-- Convert schema '/Users/fge7z/Code/work/judoon/share/migrations/_source/deploy/5/001-auto.yml' to '/Users/fge7z/Code/work/judoon/share/migrations/_source/deploy/6/001-auto.yml':;

;
BEGIN;

;

DROP TABLE datasets;
CREATE TABLE datasets (
    id INTEGER PRIMARY KEY NOT NULL,
    user_id integer NOT NULL,
    name text NOT NULL,
    notes text NOT NULL,
    original text NOT NULL,
    data text NOT NULL,
    tablename text NOT NULL,
    nbr_rows integer NOT NULL,
    nbr_columns integer NOT NULL,
    permission text NOT NULL DEFAULT 'private' CHECK (permission IN ('private', 'public')),
    FOREIGN KEY(user_id) REFERENCES users(id)
);

COMMIT;

