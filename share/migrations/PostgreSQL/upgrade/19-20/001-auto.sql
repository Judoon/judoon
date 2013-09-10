-- Convert schema '/Users/fge7z/code/work/judoon/share/scripts/schema/../../../share/migrations/_source/deploy/19/001-auto.yml' to '/Users/fge7z/code/work/judoon/share/scripts/schema/../../../share/migrations/_source/deploy/20/001-auto.yml':;

;
BEGIN;

ALTER TABLE dataset_columns ADD COLUMN data_type text;

UPDATE dataset_columns
  SET data_type=(
    SELECT data_type FROM tt_dscolumn_datatypes WHERE id=data_type_id
  );

ALTER TABLE dataset_columns ALTER COLUMN data_type SET NOT NULL;

;
ALTER TABLE dataset_columns DROP CONSTRAINT dataset_columns_fk_data_type_id;

;
DROP INDEX dataset_columns_idx_data_type_id;

;
ALTER TABLE dataset_columns DROP COLUMN data_type_id;

;
ALTER TABLE tt_dscolumn_datatypes DROP COLUMN id;

;

;
CREATE INDEX dataset_columns_idx_data_type on dataset_columns (data_type);

;
ALTER TABLE dataset_columns ADD CONSTRAINT dataset_columns_fk_data_type FOREIGN KEY (data_type)
  REFERENCES tt_dscolumn_datatypes (data_type) ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE tt_dscolumn_datatypes ADD PRIMARY KEY (data_type);

;

COMMIT;

