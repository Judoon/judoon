-- Convert schema '/Users/fge7z/code/judoon/mockapp/Judoon-Web/share/migrations/_source/deploy/2/001-auto.yml' to '/Users/fge7z/code/judoon/mockapp/Judoon-Web/share/migrations/_source/deploy/1/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE columns (
  id INTEGER PRIMARY KEY NOT NULL,
  dataset_id integer NOT NULL,
  name text NOT NULL,
  sort integer NOT NULL,
  is_accession integer NOT NULL DEFAULT 0,
  accession_type text NOT NULL,
  is_url integer NOT NULL DEFAULT 0,
  url_root text NOT NULL,
  shortname text,
  FOREIGN KEY(dataset_id) REFERENCES datasets(id)
);

;
CREATE INDEX columns_idx_dataset_id ON columns (dataset_id);

;
DROP TABLE dataset_columns;

;

COMMIT;

