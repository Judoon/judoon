-- Convert schema '/Users/fge7z/Code/work/judoon/share/migrations/_source/deploy/12/001-auto.yml' to '/Users/fge7z/Code/work/judoon/share/migrations/_source/deploy/13/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE dataset_columns ADD COLUMN created timestamp with time zone;
UPDATE dataset_columns SET created=now();
ALTER TABLE dataset_columns ALTER COLUMN created SET NOT NULL;

;
ALTER TABLE dataset_columns ADD COLUMN modified timestamp with time zone;
UPDATE dataset_columns SET modified=now();
ALTER TABLE dataset_columns ALTER COLUMN modified SET NOT NULL;

;
ALTER TABLE datasets ADD COLUMN created timestamp with time zone;
UPDATE datasets SET created=now();
ALTER TABLE datasets ALTER COLUMN created SET NOT NULL;

;
ALTER TABLE datasets ADD COLUMN modified timestamp with time zone;
UPDATE datasets SET modified=now();
ALTER TABLE datasets ALTER COLUMN modified SET NOT NULL;

;
ALTER TABLE page_columns ADD COLUMN created timestamp with time zone;
UPDATE page_columns SET created=now();
ALTER TABLE page_columns ALTER COLUMN created SET NOT NULL;

;
ALTER TABLE page_columns ADD COLUMN modified timestamp with time zone;
UPDATE page_columns SET modified=now();
ALTER TABLE page_columns ALTER COLUMN modified SET NOT NULL;

;
ALTER TABLE pages ADD COLUMN created timestamp with time zone;
UPDATE pages SET created=now();
ALTER TABLE pages ALTER COLUMN created SET NOT NULL;

;
ALTER TABLE pages ADD COLUMN modified timestamp with time zone;
UPDATE pages SET modified=now();
ALTER TABLE pages ALTER COLUMN modified SET NOT NULL;

;
ALTER TABLE users ADD COLUMN created timestamp with time zone;
UPDATE users SET created=now();
ALTER TABLE users ALTER COLUMN created SET NOT NULL;

;
ALTER TABLE users ADD COLUMN modified timestamp with time zone;
UPDATE users SET modified=now();
ALTER TABLE users ALTER COLUMN modified SET NOT NULL;

;

COMMIT;

