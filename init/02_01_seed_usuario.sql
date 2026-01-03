BEGIN;

WITH new_loc AS (
  INSERT INTO event_location (
    venue_name, address_line1, address_line2,
    city, state, country, postal_code, capacity,
    created_at, updated_at
  )
  VALUES (
    'Teatro Aurora',
    'Av. Central 123',
    'Piso 2, Local 5',
    'Ciudad de México',
    'CDMX',
    'MX',
    '06000',
    1200,
    NOW(), NOW()
  )
  RETURNING event_location_id
),

sec_a AS (
  INSERT INTO section (section_name, event_location_id, created_at, updated_at)
  SELECT 'Platea A', event_location_id, NOW(), NOW()
  FROM new_loc
  RETURNING section_id
),
sec_b AS (
  INSERT INTO section (section_name, event_location_id, created_at, updated_at)
  SELECT 'Balcón', event_location_id, NOW(), NOW()
  FROM new_loc
  RETURNING section_id
)

INSERT INTO seat (seat_no, row_no, section_id, created_at, updated_at)
SELECT seat_no, row_no, section_id, NOW(), NOW()
FROM (
  SELECT to_char(n, 'FM999') AS seat_no, r.row_no,
         (SELECT section_id FROM sec_a) AS section_id
  FROM generate_series(1, 12) AS g(n)
  CROSS JOIN (VALUES ('A'), ('B'), ('C')) AS r(row_no)

  UNION ALL

  SELECT to_char(n, 'FM999') AS seat_no, r.row_no,
         (SELECT section_id FROM sec_b) AS section_id
  FROM generate_series(1, 8) AS g(n)
  CROSS JOIN (VALUES ('A'), ('B')) AS r(row_no)
) s
RETURNING seat_id;

COMMIT;


BEGIN;

WITH new_loc AS (
  INSERT INTO event_location (
    venue_name, address_line1, address_line2,
    city, state, country, postal_code, capacity,
    created_at, updated_at
  )
  VALUES (
    'Auditorio Reforma',
    'Calz. de la Reforma 456',
    NULL,
    'Ciudad de México',
    'CDMX',
    'MX',
    '06100',
    1500,
    NOW(), NOW()
  )
  RETURNING event_location_id
),

sec_vip AS (
  INSERT INTO section (section_name, event_location_id, created_at, updated_at)
  SELECT 'VIP', event_location_id, NOW(), NOW()
  FROM new_loc
  RETURNING section_id
),

sec_general AS (
  INSERT INTO section (section_name, event_location_id, created_at, updated_at)
  SELECT 'General', event_location_id, NOW(), NOW()
  FROM new_loc
  RETURNING section_id
),

sec_balcony AS (
  INSERT INTO section (section_name, event_location_id, created_at, updated_at)
  SELECT 'Balcony', event_location_id, NOW(), NOW()
  FROM new_loc
  RETURNING section_id
)

INSERT INTO seat (seat_no, row_no, section_id, created_at, updated_at)
SELECT seat_no, row_no, section_id, NOW(), NOW()
FROM (
  SELECT to_char(n, 'FM999') AS seat_no,
         r.row_no,
         (SELECT section_id FROM sec_vip) AS section_id
  FROM generate_series(1, 12) AS g(n)
  CROSS JOIN (VALUES ('A'), ('B')) AS r(row_no)

  UNION ALL

  SELECT to_char(n, 'FM999') AS seat_no,
         r.row_no,
         (SELECT section_id FROM sec_general) AS section_id
  FROM generate_series(1, 20) AS g(n)
  CROSS JOIN (VALUES ('A'), ('B'), ('C'), ('D'), ('E')) AS r(row_no)

  UNION ALL

  SELECT to_char(n, 'FM999') AS seat_no,
         r.row_no,
         (SELECT section_id FROM sec_balcony) AS section_id
  FROM generate_series(1, 15) AS g(n)
  CROSS JOIN (VALUES ('BA'), ('BB')) AS r(row_no)
) s
RETURNING seat_id;

COMMIT;




INSERT INTO company (company_name, tax_id)
VALUES 
('Eventia Productions', 'EVP-980624-5R2'), 
('Christian company', 'SAAT-CEPE13');

INSERT INTO credential (
    email,
    nickname,
    password_hash,
    role,
    is_active,
    is_email_verified
)
VALUES (
    'user@example.com',
    'user',
    '$2a$12$r5MNgjPdF/Abwnq.LGgG/eMWBB19DYfSkmPHPfANIe7xLUwP14Cna',
    'attendee',
    TRUE,
    FALSE
),
('user2@example.com',
    'user_admin',
    '$2a$12$r5MNgjPdF/Abwnq.LGgG/eMWBB19DYfSkmPHPfANIe7xLUwP14Cna',
    'admin',
    TRUE,
    FALSE
),
('user3@example.com',
    'user_organizer',
    '$2a$12$r5MNgjPdF/Abwnq.LGgG/eMWBB19DYfSkmPHPfANIe7xLUwP14Cna',
    'organizer',
    TRUE,
    FALSE
),
('chris@example.com',
    'chris',
    '$2a$12$MkyTUDIormRibYauVt.4He4ZyNIOl9C5Ay90Btf88VJMU5GYOZ6PW',
    'organizer',
    TRUE,
    FALSE
)
;

INSERT INTO attendee (
    first_name,
    last_name,
    middle_name,
    credential_id
)
VALUES (
    'John',
    'Perez',
    'Gomez',
    1
);

INSERT INTO organizer (
  first_name,
  last_name,
  middle_name,
  company_id,
  credential_id
) VALUES (
  'María',
  'López',
  NULL,
  1,
  3
),
(
  'Chris',
  'Super',
  NULL,
  2,
  4
);


BEGIN;

WITH target_attendee AS (
  SELECT a.attendee_id
  FROM attendee a
  JOIN credential c ON c.credential_id = a.credential_id
  WHERE c.email = 'user@example.com'
  LIMIT 1
), pm AS (
  -- Create a payment method for that attendee
  INSERT INTO payment_method (attendee_id)
  SELECT attendee_id FROM target_attendee
  RETURNING payment_method_id, attendee_id
), card_ins AS (
  -- Attach a tokenized card to that payment method
  INSERT INTO card (
    payment_method_id, card_token, card_brand, last4, exp_month, exp_year
  )
  SELECT
    payment_method_id,
    'tok_test_visa_4242',  -- fake PSP token for testing
    'visa',
    '4242',
    12,
    (EXTRACT(YEAR FROM now())::int + 3)  -- valid for a few years
  FROM pm
  RETURNING card_id, payment_method_id
), pay AS (
  -- Create a payment snapshot (no reservation_id needed)
  INSERT INTO payment (
    purchase_at,
    subtotal, tax_percentage, tax_amount, total_amount,
    ticket_quantity,
    attendee_id,
    stripe_payment_intent_id
  )
  SELECT
    now(),
    100.00,               -- subtotal
    16.00,                -- VAT %
    ROUND(100.00 * 0.16, 2) AS tax_amount,
    ROUND(100.00 + (100.00 * 0.16), 2) AS total_amount,
    2, -- buying 2 tickets
    pm.attendee_id,
    'seed_pi_1'           --cualquier valor de prueba
  FROM pm
  RETURNING payment_id
)
SELECT
  (SELECT attendee_id FROM pm)            AS attendee_id,
  (SELECT payment_method_id FROM pm)      AS payment_method_id,
  (SELECT card_id FROM card_ins)          AS card_id,
  (SELECT payment_id FROM pay)            AS payment_id;

COMMIT;