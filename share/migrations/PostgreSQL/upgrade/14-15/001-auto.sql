-- Convert schema '/Users/fge7z/code/work/judoon/share/scripts/schema/../../../share/migrations/_source/deploy/14/001-auto.yml' to '/Users/fge7z/code/work/judoon/share/scripts/schema/../../../share/migrations/_source/deploy/15/001-auto.yml':;

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


INSERT INTO tt_accession_types (accession_type, accession_domain) VALUES
  ('entrez_gene_id',     'biology'),
  ('entrez_gene_symbol', 'biology'),
  ('entrez_refseq_id',   'biology'),
  ('entrez_protein_id',  'biology'),
  ('entrez_unigene_id',  'biology'),
  ('pubmed_id',          'biology'),
  ('uniprot_acc',        'biology'),
  ('uniprot_id',         'biology'),
  ('flybase_id',         'biology'),
  ('wormbase_id',        'biology')
;

ALTER TABLE dataset_columns ADD COLUMN accession_type_id integer;

;
CREATE INDEX dataset_columns_idx_accession_type_id on dataset_columns (accession_type_id);

;
ALTER TABLE dataset_columns ADD CONSTRAINT dataset_columns_fk_accession_type_id FOREIGN KEY (accession_type_id)
  REFERENCES tt_accession_types (id) ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;

UPDATE dataset_columns AS dscols
  SET accession_type_id = (
    SELECT id FROM tt_accession_types AS tt
    WHERE tt.accession_type = dscols.accession_type
  )
  WHERE accession_type != '';


;
ALTER TABLE dataset_columns DROP COLUMN is_accession;

;
ALTER TABLE dataset_columns DROP COLUMN accession_domain;

;
ALTER TABLE dataset_columns DROP COLUMN accession_type;

;

COMMIT;

