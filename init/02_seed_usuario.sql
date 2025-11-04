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



INSERT INTO company (company_name, tax_id)
VALUES ('Eventia Productions', 'EVP-980624-5R2');

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
    '$2a$12$ExTBlqCQV17Rq1CFjB1O9OMkZQUANE5cbEtivSo9y9u2HmxVrwqhW',
    'attendee',
    TRUE,
    FALSE
),
('user2@example.com',
    'user_admin',
    '$2a$12$ExTBlqCQV17Rq1CFjB1O9OMkZQUANE5cbEtivSo9y9u2HmxVrwqhW',
    'admin',
    TRUE,
    FALSE
),
('user3@example.com',
    'user_organizer',
    '$2a$12$ExTBlqCQV17Rq1CFjB1O9OMkZQUANE5cbEtivSo9y9u2HmxVrwqhW',
    'organizer',
    TRUE,
    FALSE)
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
);

INSERT INTO event_seat_status (status_name) VALUES
('available'),
('reserved'),
('sold'),
('blocked');


INSERT INTO ticket_status (status_name) VALUES
('sold'),
('checked_in'),
('refunded'),
('canceled');


INSERT INTO refund_status (status_name) VALUES
('requested'),
('approved'),
('processed'),
('rejected');

INSERT INTO event_image_type (code, description)
VALUES
  ('cover',  'Main cover image'),
  ('banner', 'Wide banner image'),
  ('gallery','Gallery image');