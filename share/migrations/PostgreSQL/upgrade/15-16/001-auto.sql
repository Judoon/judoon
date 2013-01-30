-- Convert schema '/Users/fge7z/code/work/judoon/share/scripts/schema/../../../share/migrations/_source/deploy/15/001-auto.yml' to '/Users/fge7z/code/work/judoon/share/scripts/schema/../../../share/migrations/_source/deploy/16/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE users ALTER COLUMN username TYPE character varying(40);

;

COMMIT;

