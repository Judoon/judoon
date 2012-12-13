-- Convert schema '/Users/fge7z/Code/work/judoon/share/migrations/_source/deploy/11/001-auto.yml' to '/Users/fge7z/Code/work/judoon/share/migrations/_source/deploy/10/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE users DROP CONSTRAINT email_address_unique;

;

COMMIT;

