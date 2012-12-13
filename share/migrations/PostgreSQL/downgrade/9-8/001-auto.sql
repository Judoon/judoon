-- Convert schema '/Users/fge7z/Code/work/judoon/share/migrations/_source/deploy/9/001-auto.yml' to '/Users/fge7z/Code/work/judoon/share/migrations/_source/deploy/8/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE users ADD COLUMN phone_number text;

;
ALTER TABLE users ADD COLUMN mail_address text;

;

COMMIT;

