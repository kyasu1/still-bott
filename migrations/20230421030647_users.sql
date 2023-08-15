CREATE TABLE IF NOT EXISTS users
(
  id        TEXT PRIMARY KEY NOT NULL,
  name      TEXT NOT NULL,
  username  TEXT NOT NULL,
  token     TEXT NOT NULL
);

