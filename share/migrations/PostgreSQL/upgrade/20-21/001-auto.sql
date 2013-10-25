-- Convert schema '/Users/fge7z/code/work/judoon/share/migrations/_source/deploy/20/001-auto.yml' to '/Users/fge7z/code/work/judoon/share/migrations/_source/deploy/21/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE datasets RENAME COLUMN notes TO description;

;

COMMIT;

