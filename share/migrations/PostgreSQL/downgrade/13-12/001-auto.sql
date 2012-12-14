-- Convert schema '/Users/fge7z/Code/work/judoon/share/migrations/_source/deploy/13/001-auto.yml' to '/Users/fge7z/Code/work/judoon/share/migrations/_source/deploy/12/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE dataset_columns DROP COLUMN created;

;
ALTER TABLE dataset_columns DROP COLUMN modified;

;
ALTER TABLE datasets DROP COLUMN created;

;
ALTER TABLE datasets DROP COLUMN modified;

;
ALTER TABLE page_columns DROP COLUMN created;

;
ALTER TABLE page_columns DROP COLUMN modified;

;
ALTER TABLE pages DROP COLUMN created;

;
ALTER TABLE pages DROP COLUMN modified;

;
ALTER TABLE users DROP COLUMN created;

;
ALTER TABLE users DROP COLUMN modified;

;

COMMIT;

