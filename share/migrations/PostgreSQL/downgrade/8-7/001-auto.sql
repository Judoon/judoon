-- Convert schema '/Users/fge7z/Code/work/judoon/share/migrations/_source/deploy/8/001-auto.yml' to '/Users/fge7z/Code/work/judoon/share/migrations/_source/deploy/7/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE page_columns DROP COLUMN sort;

;

COMMIT;

