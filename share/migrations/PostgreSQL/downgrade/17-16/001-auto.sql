-- Convert schema '/Users/fge7z/code/work/judoon/share/scripts/schema/../../../share/migrations/_source/deploy/17/001-auto.yml' to '/Users/fge7z/code/work/judoon/share/scripts/schema/../../../share/migrations/_source/deploy/16/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE dataset_columns DROP CONSTRAINT dataset_id_name_unique;

;

COMMIT;

