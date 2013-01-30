-- Convert schema '/Users/fge7z/code/work/judoon/share/scripts/schema/../../../share/migrations/_source/deploy/14/001-auto.yml' to '/Users/fge7z/code/work/judoon/share/scripts/schema/../../../share/migrations/_source/deploy/13/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE dataset_columns DROP CONSTRAINT dataset_columns_fk_data_type_id;

;
DROP INDEX dataset_columns_idx_data_type_id;

;
ALTER TABLE dataset_columns DROP COLUMN data_type_id;

;
ALTER TABLE dataset_columns DROP COLUMN accession_domain;

;
ALTER TABLE dataset_columns ADD COLUMN is_url integer DEFAULT 0 NOT NULL;

;
ALTER TABLE dataset_columns ADD COLUMN url_root text NOT NULL;

;
ALTER TABLE dataset_columns ALTER COLUMN is_accession TYPE integer;

;
DROP TABLE tt_dscolumn_datatypes CASCADE;

;

COMMIT;

