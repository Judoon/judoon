-- Convert schema '/Users/fge7z/Code/work/judoon/share/migrations/_source/deploy/7/001-auto.yml' to '/Users/fge7z/Code/work/judoon/share/migrations/_source/deploy/8/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE page_columns ADD COLUMN sort integer;

UPDATE page_columns AS pc1
SET sort = (
  SELECT count(pc2.id) FROM page_columns AS pc2
  WHERE pc2.page_id=pc1.page_id AND pc2.id <= pc1.id
  GROUP BY (pc2.page_id)
);  
;

ALTER TABLE page_columns ALTER COLUMN sort SET NOT NULL;

COMMIT;

