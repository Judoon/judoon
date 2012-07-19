-- Convert schema '/Users/fge7z/Code/work/judoon/share/migrations/_source/deploy/4/001-auto.yml' to '/Users/fge7z/Code/work/judoon/share/migrations/_source/deploy/5/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE datasets ADD COLUMN permission text NOT NULL DEFAULT 'private' CHECK (permission IN ('private', 'public'));;

;
ALTER TABLE pages ADD COLUMN permission text NOT NULL DEFAULT 'private' CHECK (permission IN ('private', 'public'));;

;
DROP TABLE permissions;

;

COMMIT;

