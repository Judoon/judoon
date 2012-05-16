-- Convert schema '/Users/fge7z/code/work/judoon/share/migrations/_source/deploy/3/001-auto.yml' to '/Users/fge7z/code/work/judoon/share/migrations/_source/deploy/2/001-auto.yml':;

;
BEGIN;

;
CREATE TEMPORARY TABLE users_temp_alter (
  id INTEGER PRIMARY KEY NOT NULL,
  login text NOT NULL,
  name text NOT NULL
);

;
INSERT INTO users_temp_alter( id, name) SELECT id, name FROM users;

;
DROP TABLE users;

;
CREATE TABLE users (
  id INTEGER PRIMARY KEY NOT NULL,
  login text NOT NULL,
  name text NOT NULL
);

;
CREATE UNIQUE INDEX login_unique02 ON users (login);

;
INSERT INTO users SELECT id, login, name FROM users_temp_alter;

;
DROP TABLE users_temp_alter;

;
DROP TABLE roles;

;
DROP TABLE user_roles;

;

COMMIT;

