-- Convert schema '/Users/fge7z/Code/work/judoon/share/migrations/_source/deploy/10/001-auto.yml' to '/Users/fge7z/Code/work/judoon/share/migrations/_source/deploy/9/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE users ALTER COLUMN active TYPE character(1);
ALTER TABLE users ALTER COLUMN active DROP DEFAULT;

COMMIT;

