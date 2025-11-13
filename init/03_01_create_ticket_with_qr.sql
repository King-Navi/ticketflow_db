-- Requiere pgcrypto si usas gen_random_uuid()
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
  v_sold_id     integer;
  v_refunded_id integer;
  v_ticket      ticket%ROWTYPE;
  v_qr_id       integer;
  v_token       uuid;
BEGIN
  -- Asegura que exista el asiento y serializa intentos concurrentes
  PERFORM 1 FROM event_seat es
   WHERE es.event_seat_id = p_event_seat_id
   FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'event_seat_id % not found', p_event_seat_id
      USING ERRCODE = 'foreign_key_violation';
  END IF;

  -- IDs de estados requeridos
  SELECT ts.ticket_status_id INTO v_sold_id
    FROM ticket_status ts WHERE ts.status_name = 'sold';
  IF v_sold_id IS NULL THEN
    RAISE EXCEPTION 'ticket_status "sold" is missing';
  END IF;

  SELECT ts.ticket_status_id INTO v_refunded_id
    FROM ticket_status ts WHERE ts.status_name = 'refunded';
  IF v_refunded_id IS NULL THEN
    RAISE EXCEPTION 'ticket_status "refunded" is missing';
  END IF;

  -- ¿Ya hay ticket para este asiento?
  SELECT t.* INTO v_ticket
    FROM ticket t
   WHERE t.event_seat_id = p_event_seat_id
   FOR UPDATE;

  IF NOT FOUND THEN
    -- A) Crear ticket nuevo + QR
    INSERT INTO ticket AS t(
      category_label, seat_label, unit_price,
      checked_in_at, payment_id, ticket_status_id, event_seat_id,
      created_at, updated_at
    )
    VALUES (
      p_category_label, p_seat_label, p_unit_price,
      NULL, p_payment_id, v_sold_id, p_event_seat_id,
      now(), now()
    )
    RETURNING t.* INTO v_ticket;

    INSERT INTO ticket_qr AS q(ticket_id)
    VALUES (v_ticket.ticket_id)
    RETURNING q.ticket_qr_id, q.token INTO v_qr_id, v_token;

    RETURN QUERY
      SELECT v_ticket.ticket_id, v_qr_id, v_token, false;
    RETURN;
  END IF;

  -- B) Existe ticket: solo permitir si está refunded (re-emisión)
  IF v_ticket.ticket_status_id = v_refunded_id THEN
    UPDATE ticket AS t
       SET category_label   = p_category_label,
           seat_label       = p_seat_label,
           unit_price       = p_unit_price,
           checked_in_at    = NULL,
           payment_id       = p_payment_id,
           ticket_status_id = v_sold_id,
           updated_at       = now()
     WHERE t.ticket_id = v_ticket.ticket_id
     RETURNING t.* INTO v_ticket;

    -- Upsert del QR
    SELECT q.ticket_qr_id, q.token INTO v_qr_id, v_token
      FROM ticket_qr q
     WHERE q.ticket_id = v_ticket.ticket_id
     FOR UPDATE;

    IF NOT FOUND THEN
      INSERT INTO ticket_qr AS q(ticket_id)
      VALUES (v_ticket.ticket_id)
      RETURNING q.ticket_qr_id, q.token INTO v_qr_id, v_token;
    ELSE
      UPDATE ticket_qr AS q
         SET token      = gen_random_uuid(),
             updated_at = now()
       WHERE q.ticket_qr_id = v_qr_id
       RETURNING q.token INTO v_token;
    END IF;

    RETURN QUERY
      SELECT v_ticket.ticket_id, v_qr_id, v_token, true;
    RETURN;
  ELSE
    -- No está refunded → no se puede crear/reemitir
    RAISE EXCEPTION
      'Seat % already has a non-refunded ticket (ticket_id %, status_id %)',
      p_event_seat_id, v_ticket.ticket_id, v_ticket.ticket_status_id
      USING ERRCODE = 'unique_violation';
  END IF;
END;
$$;
