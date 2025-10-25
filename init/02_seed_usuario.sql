INSERT INTO "Credential" (
  "email",
  "nickname",
  "passwordHash",
  "role"
) VALUES (
  'user@example.com',
  'user',
  '$2a$12$EQZhOIH1auLWqyp6dDlQ5.dE/l2MVN95bay98rpN.NwqvXlouvWwy',
  'attendee'
)
RETURNING "idCredential";

INSERT INTO "Attendee" (
  "firstName",
  "lastName",
  "middleName",
  "idCredential"
) VALUES (
  'John',
  'Perez',
  'Gomez',
  1
);
