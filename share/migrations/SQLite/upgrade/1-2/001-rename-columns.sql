BEGIN;

ALTER TABLE columns RENAME TO dataset_columns;

COMMIT;
