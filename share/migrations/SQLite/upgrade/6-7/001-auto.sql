-- Convert schema '/Users/fge7z/Code/work/judoon/share/migrations/_source/deploy/6/001-auto.yml' to '/Users/fge7z/Code/work/judoon/share/migrations/_source/deploy/7/001-auto.yml':;

;
BEGIN;

;
CREATE UNIQUE INDEX dataset_id_shortname_unique ON dataset_columns (dataset_id, shortname);

;

COMMIT;

