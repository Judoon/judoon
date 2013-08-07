-- Convert schema '/Users/fge7z/code/work/judoon/share/scripts/schema/../../../share/migrations/_source/deploy/19/001-auto.yml' to '/Users/fge7z/code/work/judoon/share/scripts/schema/../../../share/migrations/_source/deploy/18/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE "tt_accession_types" (
  "id" serial NOT NULL,
  "accession_type" text NOT NULL,
  "accession_domain" text NOT NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT "accession_type_unique" UNIQUE ("accession_type")
);

;
ALTER TABLE dataset_columns ADD COLUMN accession_type_id integer;

;
CREATE INDEX dataset_columns_idx_accession_type_id on dataset_columns (accession_type_id);

;
ALTER TABLE dataset_columns ADD CONSTRAINT dataset_columns_fk_accession_type_id FOREIGN KEY (accession_type_id)
  REFERENCES tt_accession_types (id) ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;

COMMIT;

