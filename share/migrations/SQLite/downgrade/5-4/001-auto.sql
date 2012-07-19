-- Convert schema '/Users/fge7z/Code/work/judoon/share/migrations/_source/deploy/5/001-auto.yml' to '/Users/fge7z/Code/work/judoon/share/migrations/_source/deploy/4/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE permissions (
  id INTEGER PRIMARY KEY NOT NULL,
  obj_id integer NOT NULL,
  permission text NOT NULL,
  password text
);

;
CREATE UNIQUE INDEX obj_id_unique ON permissions (obj_id);

;
CREATE TEMPORARY TABLE datasets_temp_alter (
  id INTEGER PRIMARY KEY NOT NULL,
  user_id integer NOT NULL,
  name text NOT NULL,
  notes text NOT NULL,
  original text NOT NULL,
  data text NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE
);

;
INSERT INTO datasets_temp_alter( id, user_id, name, notes, original, data) SELECT id, user_id, name, notes, original, data FROM datasets;

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
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE
);

;
CREATE INDEX datasets_idx_user_id02 ON datasets (user_id);

;
INSERT INTO datasets SELECT id, user_id, name, notes, original, data FROM datasets_temp_alter;

;
DROP TABLE datasets_temp_alter;

;
CREATE TEMPORARY TABLE pages_temp_alter (
  id INTEGER PRIMARY KEY NOT NULL,
  dataset_id integer NOT NULL,
  title text NOT NULL,
  preamble text NOT NULL,
  postamble text NOT NULL,
  FOREIGN KEY (dataset_id) REFERENCES datasets(id) ON DELETE CASCADE ON UPDATE CASCADE
);

;
INSERT INTO pages_temp_alter( id, dataset_id, title, preamble, postamble) SELECT id, dataset_id, title, preamble, postamble FROM pages;

;
DROP TABLE pages;

;
CREATE TABLE pages (
  id INTEGER PRIMARY KEY NOT NULL,
  dataset_id integer NOT NULL,
  title text NOT NULL,
  preamble text NOT NULL,
  postamble text NOT NULL,
  FOREIGN KEY (dataset_id) REFERENCES datasets(id) ON DELETE CASCADE ON UPDATE CASCADE
);

;
CREATE INDEX pages_idx_dataset_id02 ON pages (dataset_id);

;
INSERT INTO pages SELECT id, dataset_id, title, preamble, postamble FROM pages_temp_alter;

;
DROP TABLE pages_temp_alter;

;

COMMIT;

