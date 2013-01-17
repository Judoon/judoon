-- Convert schema '/Users/fge7z/code/work/judoon/share/scripts/schema/../../../share/migrations/_source/deploy/15/001-auto.yml' to '/Users/fge7z/code/work/judoon/share/scripts/schema/../../../share/migrations/_source/deploy/14/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE dataset_columns DROP CONSTRAINT dataset_columns_fk_accession_type_id;

;
DROP INDEX dataset_columns_idx_accession_type_id;

;
ALTER TABLE dataset_columns DROP COLUMN accession_type_id;

;
ALTER TABLE dataset_columns ADD COLUMN is_accession boolean DEFAULT '0' NOT NULL;

;
ALTER TABLE dataset_columns ADD COLUMN accession_domain text NOT NULL;

;
ALTER TABLE dataset_columns ADD COLUMN accession_type text NOT NULL;

;
DROP TABLE tt_accession_types CASCADE;

;

COMMIT;

