-- Convert schema '/Users/fge7z/code/work/judoon/share/scripts/schema/../../../share/migrations/_source/deploy/20/001-auto.yml' to '/Users/fge7z/code/work/judoon/share/scripts/schema/../../../share/migrations/_source/deploy/19/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE dataset_columns DROP CONSTRAINT dataset_columns_fk_data_type;

;
ALTER TABLE tt_dscolumn_datatypes DROP CONSTRAINT ;

;
DROP INDEX dataset_columns_idx_data_type;

;
ALTER TABLE dataset_columns DROP COLUMN data_type;

;
ALTER TABLE dataset_columns ADD COLUMN data_type_id integer NOT NULL;

;
ALTER TABLE tt_dscolumn_datatypes ADD COLUMN id serial NOT NULL;

;
CREATE INDEX dataset_columns_idx_data_type_id on dataset_columns (data_type_id);

;
ALTER TABLE dataset_columns ADD CONSTRAINT dataset_columns_fk_data_type_id FOREIGN KEY (data_type_id)
  REFERENCES tt_dscolumn_datatypes (id) ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE tt_dscolumn_datatypes ADD PRIMARY KEY (id);

;
ALTER TABLE tt_dscolumn_datatypes ADD CONSTRAINT tt_dscolumn_datatypes_data_type UNIQUE (data_type);

;

COMMIT;

