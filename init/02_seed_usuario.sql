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
);

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
