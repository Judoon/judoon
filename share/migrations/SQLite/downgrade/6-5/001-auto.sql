-- Convert schema '/Users/fge7z/Code/work/judoon/share/migrations/_source/deploy/6/001-auto.yml' to '/Users/fge7z/Code/work/judoon/share/migrations/_source/deploy/5/001-auto.yml':;

;
BEGIN;

;
CREATE TEMPORARY TABLE datasets_temp_alter (
  id INTEGER PRIMARY KEY NOT NULL,
  user_id integer NOT NULL,
  name text NOT NULL,
  notes text NOT NULL,
  original text NOT NULL,
  data text NOT NULL,
  permission text NOT NULL DEFAULT 'private',
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE
);

;
INSERT INTO datasets_temp_alter( id, user_id, name, notes, original, data, permission) SELECT id, user_id, name, notes, original, data, permission FROM datasets;

;
DROP TABLE datasets;

;
CREATE TABLE datasets (
  id INTEGER PRIMARY KEY NOT NULL,
  user_id integer NOT NULL,
  name text NOT NULL,
  notes text NOT NULL,
  original text NOT NULL,
  data text NOT NULL,
  permission text NOT NULL DEFAULT 'private',
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE
);

;
CREATE INDEX datasets_idx_user_id02 ON datasets (user_id);

;
INSERT INTO datasets SELECT id, user_id, name, notes, original, data, permission FROM datasets_temp_alter;

;
DROP TABLE datasets_temp_alter;

;

COMMIT;

