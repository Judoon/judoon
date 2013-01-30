-- Convert schema '/Users/fge7z/Code/work/judoon/share/migrations/_source/deploy/9/001-auto.yml' to '/Users/fge7z/Code/work/judoon/share/migrations/_source/deploy/10/001-auto.yml':;

;
BEGIN;

;

ALTER TABLE users RENAME COLUMN active TO active_old;
ALTER TABLE users ADD COLUMN active boolean DEFAULT true NOT NULL;
UPDATE users SET active=false WHERE active_old != '1';
ALTER TABLE users DROP COLUMN active_old;

COMMIT;

