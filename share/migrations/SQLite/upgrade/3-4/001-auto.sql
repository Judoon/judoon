-- Convert schema '/Users/fge7z/Code/work/judoon/share/migrations/_source/deploy/3/001-auto.yml' to '/Users/fge7z/Code/work/judoon/share/migrations/_source/deploy/4/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE permissions (
  id INTEGER PRIMARY KEY NOT NULL,
  obj_id integer NOT NULL,
  permission text NOT NULL CHECK (permission IN ('private','public','password')),
  password text
);

;
CREATE UNIQUE INDEX obj_id_unique ON permissions (obj_id);

;

COMMIT;

