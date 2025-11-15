-- Required for UUID generation (used by QR tokens)
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ============================
-- 1. Auth / Accounts
-- ============================

CREATE TABLE credential (
    credential_id          integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    email                  varchar(100) NOT NULL UNIQUE,
    nickname               varchar(100) NOT NULL UNIQUE,
    password_hash          varchar(255) NOT NULL,
    role                   varchar(50)  NOT NULL
        CHECK (role IN ('attendee','organizer','admin')),
    is_active              boolean      NOT NULL DEFAULT TRUE,
    is_email_verified      boolean      NOT NULL DEFAULT FALSE,
    created_at             timestamptz  NOT NULL DEFAULT now(),
    updated_at             timestamptz  NOT NULL DEFAULT now(),
    last_login             timestamptz
);

CREATE TABLE password_reset_token (
  password_reset_token_id  integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  credential_id            integer      NOT NULL
      REFERENCES credential (credential_id) ON DELETE CASCADE,
  token_hash               varchar(64)  NOT NULL,
  expires_at               timestamptz  NOT NULL,
  used_at                  timestamptz,
  created_ip               inet,
  created_ua               varchar(300),
  created_at               timestamptz  NOT NULL DEFAULT now(),
  updated_at               timestamptz  NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX uq_password_reset_token_hash
  ON password_reset_token (token_hash);

CREATE INDEX idx_password_reset_token_credential_active
  ON password_reset_token (credential_id, expires_at)
  WHERE used_at IS NULL;

CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS trigger AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_password_reset_token_updated_at
BEFORE UPDATE ON password_reset_token
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();


-- ============================
-- 2. Company / Organizer / Attendee
-- ============================

CREATE TABLE company (
    company_id     integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    company_name   varchar(100) NOT NULL,
    tax_id         varchar(100) NOT NULL,
    created_at     timestamptz  NOT NULL DEFAULT now(),
    updated_at     timestamptz  NOT NULL DEFAULT now()
);

CREATE TABLE attendee (
    attendee_id    integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    first_name     varchar(100) NOT NULL,
    last_name      varchar(100) NOT NULL,
    middle_name    varchar(100),
    credential_id  integer      NOT NULL UNIQUE
        REFERENCES credential (credential_id),
    created_at     timestamptz  NOT NULL DEFAULT now(),
    updated_at     timestamptz  NOT NULL DEFAULT now()
);

CREATE TABLE organizer (
    organizer_id   integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    first_name     varchar(100) NOT NULL,
    last_name      varchar(100) NOT NULL,
    middle_name    varchar(100),
    company_id     integer REFERENCES company (company_id),
    credential_id  integer NOT NULL UNIQUE
        REFERENCES credential (credential_id),
    created_at     timestamptz  NOT NULL DEFAULT now(),
    updated_at     timestamptz  NOT NULL DEFAULT now()
);

-- ============================
-- 3. Venues / Seats (physical layout)
-- ============================

CREATE TABLE event_location (
    event_location_id  integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    venue_name         varchar(150) NOT NULL,
    address_line1      varchar(200) NOT NULL,
    address_line2      varchar(200),
    city               varchar(100) NOT NULL,
    state              varchar(100),
    country            varchar(100) NOT NULL,
    postal_code        varchar(20),
    capacity           integer,
    created_at         timestamptz  NOT NULL DEFAULT now(),
    updated_at         timestamptz  NOT NULL DEFAULT now()
);

CREATE TABLE section (
    section_id         integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    section_name       varchar(100) NOT NULL,
    event_location_id  integer      NOT NULL
        REFERENCES event_location (event_location_id),
    created_at         timestamptz  NOT NULL DEFAULT now(),
    updated_at         timestamptz  NOT NULL DEFAULT now()
);

CREATE TABLE seat (
    seat_id     integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    seat_no     varchar(100) NOT NULL,
    row_no      varchar(100) NOT NULL,
    section_id  integer      NOT NULL
        REFERENCES section (section_id),
    created_at  timestamptz  NOT NULL DEFAULT now(),
    updated_at  timestamptz  NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX uq_seat_in_section_ci
  ON seat (section_id, lower(btrim(row_no)), lower(btrim(seat_no)));

CREATE UNIQUE INDEX uq_section_in_location_ci
  ON section (event_location_id, lower(btrim(section_name)));

-- ============================
-- 4. Event / Inventory per event
-- ============================
CREATE TABLE event_status (
  event_status_id  integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  code             varchar(50)  NOT NULL UNIQUE,
  description      varchar(150),
  sort_order       integer      NOT NULL DEFAULT 0,
  is_active        boolean      NOT NULL DEFAULT TRUE,
  created_at       timestamptz  NOT NULL DEFAULT now(),
  updated_at       timestamptz  NOT NULL DEFAULT now(),
  CONSTRAINT uq_event_status_code_ci UNIQUE (code)
);

ALTER TABLE event_status
  ADD CONSTRAINT chk_event_status_code_lower
  CHECK (code = lower(code));

INSERT INTO event_status (code, description, sort_order) VALUES
  ('draft',     'Draft (not visible / no sales)',            10),
  ('scheduled', 'Scheduled (pre-sale window, optional)',     20),
  ('on_sale',   'Open for reservations and sales',           30),
  ('paused',    'Temporarily paused',                        40),
  ('edit_lock', 'Edit mode: sales/reservations blocked',     50),
  ('closed',    'Sales closed (pre-event)',                  60),
  ('completed', 'Event finished',                            70),
  ('canceled',  'Event canceled',                            80);




CREATE TABLE event (
    event_id           integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    event_name         varchar(150) NOT NULL,
    category           varchar(100) NOT NULL,
    description        varchar(500) NOT NULL,
    event_date         date         NOT NULL,
    start_time         time         NOT NULL,
    end_time           time,
    company_id         integer      NOT NULL
        REFERENCES company (company_id),
    event_location_id  integer      NOT NULL
        REFERENCES event_location (event_location_id),
    event_status_id integer NOT NULL
        REFERENCES event_status(event_status_id),
    created_at         timestamptz  NOT NULL DEFAULT now(),
    updated_at         timestamptz  NOT NULL DEFAULT now(),
    CHECK (end_time IS NULL OR end_time > start_time)
        
);

CREATE INDEX idx_event_event_status_id ON event(event_status_id);

-- Trigger for 'draft' if event_status_id is null

CREATE OR REPLACE FUNCTION set_default_event_status()
RETURNS trigger AS $$
BEGIN
  IF NEW.event_status_id IS NULL THEN
    SELECT event_status_id
      INTO NEW.event_status_id
      FROM event_status
     WHERE code = 'draft';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_event_default_status
BEFORE INSERT ON event
FOR EACH ROW
EXECUTE FUNCTION set_default_event_status();

CREATE TABLE event_image_type (
    event_image_type_id  serial PRIMARY KEY,
    code                 varchar(50) NOT NULL UNIQUE, -- 'cover','banner','gallery'
    description          varchar(150),
    created_at           timestamptz NOT NULL DEFAULT now(),
    updated_at           timestamptz NOT NULL DEFAULT now()
);

INSERT INTO event_image_type (code, description)
VALUES
  ('cover',  'Main cover image'),
  ('banner', 'Wide banner image'),
  ('gallery','Gallery image');

CREATE TABLE event_image (
    event_image_id       serial PRIMARY KEY,
    event_id             integer NOT NULL
        REFERENCES event (event_id),
    event_image_type_id  integer NOT NULL
        REFERENCES event_image_type (event_image_type_id),
    image_path           varchar(300) NOT NULL,
    alt_text             varchar(200),
    sort_order           integer,
    created_at           timestamptz NOT NULL DEFAULT now(),
    updated_at           timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_event_image_event_id
    ON event_image (event_id);

CREATE INDEX idx_event_image_type_id
    ON event_image (event_image_type_id);



-- Catálogo: estado de un asiento en el contexto de un evento
-- e.g. 'available','reserved','sold','blocked'
CREATE TABLE event_seat_status (
    event_seat_status_id  integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    status_name           varchar(50) NOT NULL UNIQUE,
    created_at            timestamptz NOT NULL DEFAULT now(),
    updated_at            timestamptz NOT NULL DEFAULT now()
);

INSERT INTO event_seat_status (status_name) VALUES
('available'),
('reserved'),
('sold'),
('blocked');


-- Inventario: asiento físico mapeado a un evento específico
CREATE TABLE event_seat (
    event_seat_id         integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    event_id              integer       NOT NULL
        REFERENCES event (event_id),
    seat_id               integer       NOT NULL
        REFERENCES seat (seat_id),
    base_price            numeric(10,2) NOT NULL,
    event_seat_status_id  integer       NOT NULL
        REFERENCES event_seat_status (event_seat_status_id),
    created_at            timestamptz   NOT NULL DEFAULT now(),
    updated_at            timestamptz   NOT NULL DEFAULT now(),
    UNIQUE (event_id, seat_id)
);




-- ============================
-- 5. Reservation (pre-sale hold)
-- ============================

CREATE TABLE reservation (
    reservation_id   integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    created_at       timestamptz NOT NULL DEFAULT now(),
    updated_at       timestamptz NOT NULL DEFAULT now(),
    expiration_at    timestamptz NOT NULL,
    status           varchar(50) NOT NULL DEFAULT 'active'
        CHECK (status IN ('active','expired','converted','canceled')),
    attendee_id      integer     NOT NULL
        REFERENCES attendee (attendee_id),
    event_seat_id    integer     NOT NULL
        REFERENCES event_seat (event_seat_id)
);

-- ============================
-- 6. Payment Methods
-- ============================
-- payment_method = contenedor lógico, ligado al attendee.
-- card / crypto son detalles concretos.
-- PCI: NO guardamos CVV ni PAN completo.

CREATE TABLE payment_method (
    payment_method_id  integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    attendee_id        integer     NOT NULL
        REFERENCES attendee (attendee_id),
    created_at         timestamptz NOT NULL DEFAULT now(),
    updated_at         timestamptz NOT NULL DEFAULT now()
);

-- Tarjeta (tokenizada)
CREATE TABLE card (
    card_id             integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    payment_method_id   integer NOT NULL UNIQUE
        REFERENCES payment_method (payment_method_id),
    card_token          varchar(255) NOT NULL,  -- token del PSP
    card_brand          varchar(50)  NOT NULL,  -- 'visa','mc','amex',...
    last4               char(4)      NOT NULL,  -- últimos 4
    exp_month           smallint     NOT NULL CHECK (exp_month BETWEEN 1 AND 12),
    exp_year            smallint     NOT NULL CHECK (exp_year >= EXTRACT(YEAR FROM now())::int - 1),
    created_at          timestamptz  NOT NULL DEFAULT now(),
    updated_at          timestamptz  NOT NULL DEFAULT now()
    -- CVV no se almacena jamás
);

-- Cripto / wallet
CREATE TABLE crypto_payment (
    crypto_payment_id   integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    payment_method_id   integer NOT NULL UNIQUE
        REFERENCES payment_method (payment_method_id),
    wallet_address      varchar(300) NOT NULL,
    created_at          timestamptz  NOT NULL DEFAULT now(),
    updated_at          timestamptz  NOT NULL DEFAULT now()
);

-- ============================
-- 7. Payment (venta confirmada)
-- ============================
-- Guardamos snapshot de montos para auditoría fiscal

CREATE TABLE payment (
    payment_id              integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    purchase_at             timestamptz  NOT NULL DEFAULT now(),
    subtotal                numeric(10,2) NOT NULL,
    tax_percentage          numeric(5,2)  NOT NULL,
    tax_amount              numeric(10,2) NOT NULL,
    total_amount            numeric(10,2) NOT NULL,
    ticket_quantity         integer       NOT NULL CHECK (ticket_quantity > 0),
    attendee_id             integer       NOT NULL
        REFERENCES attendee (attendee_id),
    stripe_payment_intent_id varchar(255) NOT NULL UNIQUE,
    created_at              timestamptz   NOT NULL DEFAULT now(),
    updated_at              timestamptz   NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX uq_payment_stripe_pi
    ON payment (stripe_payment_intent_id);

CREATE INDEX idx_payment_attendee_id
    ON payment (attendee_id);
-- ============================
-- 8. Tickets
-- ============================

CREATE TABLE ticket_status (
    ticket_status_id  integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    status_name       varchar(100) NOT NULL UNIQUE,
    created_at        timestamptz  NOT NULL DEFAULT now(),
    updated_at        timestamptz  NOT NULL DEFAULT now()
);

INSERT INTO ticket_status (status_name) VALUES
('sold'),
('checked_in'),
('refunded'),
('canceled');


CREATE TABLE ticket (
    ticket_id         integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    category_label    varchar(100) NOT NULL,     -- ej "VIP", "Balcony"
    seat_label        varchar(100) NOT NULL,     -- ej "Row B Seat 12"
    unit_price        numeric(10,2) NOT NULL,    -- precio pagado por este boleto
    checked_in_at     timestamptz,
    payment_id        integer      NOT NULL
        REFERENCES payment (payment_id),
    ticket_status_id  integer      NOT NULL
        REFERENCES ticket_status (ticket_status_id),
    event_seat_id     integer      NOT NULL UNIQUE
        REFERENCES event_seat (event_seat_id),
    created_at        timestamptz  NOT NULL DEFAULT now(),
    updated_at        timestamptz  NOT NULL DEFAULT now()
);

CREATE TABLE ticket_qr (
    ticket_qr_id   integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ticket_id      integer NOT NULL
        REFERENCES ticket (ticket_id) ON DELETE CASCADE,
    token          uuid    NOT NULL UNIQUE DEFAULT gen_random_uuid(),-- payload carried in the QR
    updated_at        timestamptz  NOT NULL DEFAULT now(),
    created_at     timestamptz NOT NULL DEFAULT now()  
);

CREATE UNIQUE INDEX uq_ticket_qr_one_per_ticket
  ON ticket_qr (ticket_id);

CREATE INDEX idx_ticket_qr_token ON ticket_qr (token);

CREATE TABLE check_in_status (
    check_in_status_id smallint PRIMARY KEY,
    status_name        varchar(50) NOT NULL UNIQUE,
    created_at         timestamptz NOT NULL DEFAULT now(),
    updated_at         timestamptz NOT NULL DEFAULT now()
    -- values: 1=ok, 2=duplicate, 3=invalid, 4=outside_window
);

INSERT INTO check_in_status (check_in_status_id, status_name) VALUES
(1,'ok'),
(2,'duplicate'),
(3,'invalid'),
(4,'outside_window');


CREATE TABLE ticket_check_in (
    ticket_check_in_id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ticket_qr_id       integer NOT NULL
        REFERENCES ticket_qr (ticket_qr_id) ON DELETE RESTRICT,
    check_in_status_id smallint NOT NULL
        REFERENCES check_in_status (check_in_status_id),
    scanned_at         timestamptz NOT NULL DEFAULT now(),
    scanner_id         integer,
    created_at         timestamptz NOT NULL DEFAULT now(),
    updated_at         timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_check_in_qr_id ON ticket_check_in (ticket_qr_id);
CREATE INDEX idx_check_in_status_id ON ticket_check_in (check_in_status_id);
CREATE INDEX idx_check_in_scanned ON ticket_check_in (scanned_at);

-- ============================
-- 9. Refunds
-- ============================

CREATE TABLE refund_status (
    refund_status_id  integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    status_name       varchar(100) NOT NULL UNIQUE,
    created_at        timestamptz  NOT NULL DEFAULT now(),
    updated_at        timestamptz  NOT NULL DEFAULT now()
    -- ej: 'requested','approved','processed','rejected'
);

INSERT INTO refund_status (status_name) VALUES
('requested'),
('approved'),
('processed'),
('rejected');

CREATE TABLE refund (
    refund_id         integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    refund_date       timestamptz  NOT NULL DEFAULT now(),
    reason            varchar(500) NOT NULL,
    refund_amount     numeric(10,2) NOT NULL,
    ticket_id         integer      NOT NULL UNIQUE
        REFERENCES ticket (ticket_id),
    refund_status_id  integer      NOT NULL
        REFERENCES refund_status (refund_status_id),
    created_at        timestamptz  NOT NULL DEFAULT now(),
    updated_at        timestamptz  NOT NULL DEFAULT now()
);

-- ============================
-- 10. Helpful indexes on foreign keys
-- ============================

CREATE INDEX idx_attendee_credential_id
    ON attendee (credential_id);

CREATE INDEX idx_organizer_credential_id
    ON organizer (credential_id);

CREATE INDEX idx_organizer_company_id
    ON organizer (company_id);

CREATE INDEX idx_section_event_location_id
    ON section (event_location_id);

CREATE INDEX idx_seat_section_id
    ON seat (section_id);

CREATE INDEX idx_event_company_id
    ON event (company_id);

CREATE INDEX idx_event_event_location_id
    ON event (event_location_id);

CREATE INDEX idx_event_seat_event_id
    ON event_seat (event_id);

CREATE INDEX idx_event_seat_seat_id
    ON event_seat (seat_id);

CREATE INDEX idx_event_seat_status_id
    ON event_seat (event_seat_status_id);

CREATE INDEX idx_reservation_attendee_id
    ON reservation (attendee_id);

CREATE INDEX idx_reservation_event_seat_id
    ON reservation (event_seat_id);


CREATE INDEX idx_ticket_payment_id
    ON ticket (payment_id);

CREATE INDEX idx_ticket_ticket_status_id
    ON ticket (ticket_status_id);

CREATE INDEX idx_ticket_event_seat_id
    ON ticket (event_seat_id);

CREATE INDEX idx_refund_ticket_id
    ON refund (ticket_id);

CREATE INDEX idx_refund_refund_status_id
    ON refund (refund_status_id);
