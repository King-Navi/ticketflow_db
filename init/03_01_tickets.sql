-- Requiere pgcrypto para gen_random_uuid()
-- CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE OR REPLACE FUNCTION fn01_create_ticket_with_qr(
  p_event_seat_id   integer,
  p_payment_id      integer,
  p_category_label  varchar,
  p_seat_label      varchar,
  p_unit_price      numeric
) RETURNS TABLE (
  out_ticket_id     integer,
  out_ticket_qr_id  integer,
  out_token         uuid,
  out_reissued      boolean
)
LANGUAGE plpgsql
AS $$
DECLARE
  v_sold_id   integer;
  v_ticket    ticket%ROWTYPE;
  v_qr_id     integer;
  v_token     uuid;
BEGIN
  -- 1 Ensure event_seat exists and serialize concurrent attempts
  PERFORM 1
    FROM event_seat es
   WHERE es.event_seat_id = p_event_seat_id
   FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'event_seat_id % not found', p_event_seat_id
      USING ERRCODE = 'foreign_key_violation';
  END IF;

  SELECT ts.ticket_status_id
    INTO v_sold_id
    FROM ticket_status ts
   WHERE ts.status_name = 'sold';

  IF v_sold_id IS NULL THEN
    RAISE EXCEPTION 'ticket_status "sold" is missing';
  END IF;

  -- Always create a NEW ticket row
  INSERT INTO ticket AS t (
    category_label,
    seat_label,
    unit_price,
    checked_in_at,
    payment_id,
    ticket_status_id,
    event_seat_id,
    created_at,
    updated_at
  )
  VALUES (
    p_category_label,
    p_seat_label,
    p_unit_price,
    NULL,
    p_payment_id,
    v_sold_id,
    p_event_seat_id,
    now(),
    now()
  )
  RETURNING t.* INTO v_ticket;

  -- Create QR row for this new ticket
  INSERT INTO ticket_qr AS q (ticket_id)
  VALUES (v_ticket.ticket_id)
  RETURNING q.ticket_qr_id, q.token INTO v_qr_id, v_token;

  -- Return values (out_reissued = false: always a new ticket)
  RETURN QUERY
    SELECT v_ticket.ticket_id,
           v_qr_id,
           v_token,
           false::boolean;
END;
$$;



-- ==========================================
-- Function: fn02_get_ticket_with_event
-- Returns ticket + its event info in one row
-- ==========================================
CREATE OR REPLACE FUNCTION fn02_get_ticket_with_event(p_ticket_id integer)
RETURNS TABLE (
  ticket_id         integer,
  ticket_status_id  integer,
  category_label    varchar(100),
  seat_label        varchar(100),
  unit_price        numeric(10,2),
  checked_in_at     timestamptz,
  event_id          integer,
  event_name        varchar(150),
  event_date        date,
  start_time        time,
  end_time          time,
  event_location_id integer
) AS $$
  SELECT
    t.ticket_id,
    t.ticket_status_id,
    t.category_label,
    t.seat_label,
    t.unit_price,
    t.checked_in_at,
    e.event_id,
    e.event_name,
    e.event_date,
    e.start_time,
    e.end_time,
    e.event_location_id
  FROM ticket t
  JOIN event_seat es
    ON es.event_seat_id = t.event_seat_id
  JOIN event e
    ON e.event_id = es.event_id
  WHERE t.ticket_id = p_ticket_id;
$$ LANGUAGE sql STABLE;



CREATE OR REPLACE FUNCTION fn03_get_attendee_events_with_tickets(
  p_attendee_id        integer,
  p_event_status_code  varchar DEFAULT NULL
)
RETURNS TABLE (
  event_id           integer,
  event_name         varchar(150),
  category           varchar(100),
  description        varchar(500),
  event_date         date,
  start_time         time,
  end_time           time,
  event_status_id    integer,
  event_status_code  varchar(50),
  event_location_id  integer,
  venue_name         varchar(150),
  city               varchar(100),
  country            varchar(100),
  tickets            jsonb
)
AS $$
  SELECT
    e.event_id,
    e.event_name,
    e.category,
    e.description,
    e.event_date,
    e.start_time,
    e.end_time,
    e.event_status_id,
    evs.code AS event_status_code,
    e.event_location_id,
    el.venue_name,
    el.city,
    el.country,
    jsonb_agg(
      jsonb_build_object(
        'ticket_id',          t.ticket_id,
        'category_label',     t.category_label,
        'seat_label',         t.seat_label,
        'unit_price',         t.unit_price,
        'ticket_status_id',   t.ticket_status_id,
        'ticket_status_name', ts.status_name,
        'checked_in_at',      t.checked_in_at
      )
      ORDER BY t.ticket_id
    ) AS tickets
  FROM payment p
  JOIN ticket t
    ON t.payment_id = p.payment_id
  JOIN ticket_status ts
    ON ts.ticket_status_id = t.ticket_status_id
  JOIN event_seat es
    ON es.event_seat_id = t.event_seat_id
  JOIN event e
    ON e.event_id = es.event_id
  JOIN event_status evs
    ON evs.event_status_id = e.event_status_id
  JOIN event_location el
    ON el.event_location_id = e.event_location_id
  WHERE
    p.attendee_id = p_attendee_id
    -- Solo tickets no-refunded / no-canceled:
    AND ts.status_name IN ('sold', 'checked_in')
    -- Filtro opcional por estado de evento:
    AND (
      p_event_status_code IS NULL
      OR evs.code = lower(p_event_status_code)
    )
  GROUP BY
    e.event_id,
    e.event_name,
    e.category,
    e.description,
    e.event_date,
    e.start_time,
    e.end_time,
    e.event_status_id,
    evs.code,
    e.event_location_id,
    el.venue_name,
    el.city,
    el.country
  ORDER BY
    e.event_date,
    e.start_time,
    e.event_name;
$$ LANGUAGE sql STABLE;
