-- Convert schema '/Users/fge7z/code/work/judoon/share/scripts/schema/../../../share/migrations/_source/deploy/13/001-auto.yml' to '/Users/fge7z/code/work/judoon/share/scripts/schema/../../../share/migrations/_source/deploy/14/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE "tt_dscolumn_datatypes" (
  "id" serial NOT NULL,
  "data_type" text NOT NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT "data_type_unique" UNIQUE ("data_type")
);

INSERT INTO tt_dscolumn_datatypes (data_type) VALUES ('text'),('numeric'),('datetime'),('currency');


;
ALTER TABLE dataset_columns DROP COLUMN is_url;

;
ALTER TABLE dataset_columns DROP COLUMN url_root;

;
ALTER TABLE dataset_columns ADD COLUMN data_type_id integer;
UPDATE dataset_columns SET data_type_id=(SELECT id FROM tt_dscolumn_datatypes WHERE data_type='text');
ALTER TABLE dataset_columns ALTER COLUMN data_type_id SET NOT NULL;

;
ALTER TABLE dataset_columns ADD COLUMN accession_domain text default 'biology' NOT NULL;

;
ALTER TABLE dataset_columns RENAME COLUMN is_accession TO is_accession_old;
ALTER TABLE dataset_columns ADD COLUMN is_accession boolean default false NOT NULL;
UPDATE dataset_columns SET is_accession=is_accession_old::boolean;
ALTER TABLE dataset_columns DROP COLUMN is_accession_old;

;
CREATE INDEX dataset_columns_idx_data_type_id on dataset_columns (data_type_id);

;
ALTER TABLE dataset_columns ADD CONSTRAINT dataset_columns_fk_data_type_id FOREIGN KEY (data_type_id)
  REFERENCES tt_dscolumn_datatypes (id) ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;

COMMIT;

