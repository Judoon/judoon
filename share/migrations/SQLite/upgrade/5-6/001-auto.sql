-- Convert schema '/Users/fge7z/Code/work/judoon/share/migrations/_source/deploy/5/001-auto.yml' to '/Users/fge7z/Code/work/judoon/share/migrations/_source/deploy/6/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE datasets ADD COLUMN tablename text NOT NULL;

;

COMMIT;

