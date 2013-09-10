-- Convert schema '/Users/fge7z/code/work/judoon/share/scripts/schema/../../../share/migrations/_source/deploy/18/001-auto.yml' to '/Users/fge7z/code/work/judoon/share/scripts/schema/../../../share/migrations/_source/deploy/19/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE dataset_columns DROP CONSTRAINT dataset_columns_fk_accession_type_id;

;
DROP INDEX dataset_columns_idx_accession_type_id;

;
ALTER TABLE dataset_columns DROP COLUMN accession_type_id;

;
DROP TABLE tt_accession_types CASCADE;

;


UPDATE tt_dscolumn_datatypes SET data_type='CoreType_Datetime' WHERE data_type='datetime';
UPDATE tt_dscolumn_datatypes SET data_type='CoreType_Numeric'  WHERE data_type='numeric';
UPDATE tt_dscolumn_datatypes SET data_type='CoreType_Text'     WHERE data_type='text';
DELETE FROM tt_dscolumn_datatypes WHERE data_type='currency';

INSERT INTO tt_dscolumn_datatypes (data_type) VALUES
  ('Biology_Accession_Cmkb_ComplexAcc'),
  ('Biology_Accession_Cmkb_FamilyAcc'),
  ('Biology_Accession_Cmkb_OrthologAcc'),
  ('Biology_Accession_Entrez_GeneId'),
  ('Biology_Accession_Entrez_GeneSymbol'),
  ('Biology_Accession_Entrez_ProteinId'),
  ('Biology_Accession_Entrez_RefseqId'),
  ('Biology_Accession_Entrez_UnigeneId'),
  ('Biology_Accession_Flybase_Id'),
  ('Biology_Accession_Pubmed_Pmid'),
  ('Biology_Accession_Uniprot_Acc'),
  ('Biology_Accession_Uniprot_Id'),
  ('Biology_Accession_Wormbase_Id');


COMMIT;

