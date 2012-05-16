BEGIN;

CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    active CHAR(1) NOT NULL,
    username TEXT NOT NULL UNIQUE,
    password TEXT NOT NULL,
    password_expires TIMESTAMP,
    name TEXT NOT NULL,
    email_address TEXT NOT NULL,
    phone_number TEXT,
    mail_address TEXT
);
 
CREATE TABLE roles (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL UNIQUE
);
 
CREATE TABLE user_roles (
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE,
    role_id INTEGER NOT NULL REFERENCES roles(id) ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE,
    PRIMARY KEY (user_id, role_id)
);

CREATE TABLE datasets (
    id INTEGER PRIMARY KEY NOT NULL,
    user_id integer NOT NULL,
    name text NOT NULL,
    notes text NOT NULL,
    original text NOT NULL,
    data text NOT NULL,
    FOREIGN KEY(user_id) REFERENCES users(id)
);

CREATE TABLE "dataset_columns" (
    id INTEGER PRIMARY KEY NOT NULL,
    dataset_id integer NOT NULL,
    name text NOT NULL,
    sort integer NOT NULL,
    is_accession integer NOT NULL DEFAULT 0,
    accession_type text NOT NULL,
    is_url integer NOT NULL DEFAULT 0,
    url_root text NOT NULL,
    shortname text,
    FOREIGN KEY(dataset_id) REFERENCES datasets(id)
);

CREATE TABLE pages (
    id INTEGER PRIMARY KEY NOT NULL,
    dataset_id integer NOT NULL,
    title text NOT NULL,
    preamble text NOT NULL,
    postamble text NOT NULL,
    FOREIGN KEY(dataset_id) REFERENCES datasets(id)
);

CREATE TABLE page_columns (
     id INTEGER PRIMARY KEY NOT NULL,
     page_id integer NOT NULL,
     title text NOT NULL,
     template text NOT NULL,
     FOREIGN KEY(page_id) REFERENCES pages(id)
);



CREATE TABLE dbix_class_deploymenthandler_versions (
    id INTEGER PRIMARY KEY NOT NULL,
    version varchar(50) NOT NULL,
    ddl text,
    upgrade_sql text
);


CREATE INDEX columns_idx_dataset_id ON "dataset_columns" (dataset_id);
CREATE INDEX datasets_idx_user_id ON datasets (user_id);
CREATE UNIQUE INDEX dbix_class_deploymenthandler_versions_version ON dbix_class_deploymenthandler_versions (version);
CREATE UNIQUE INDEX login_unique ON users (login);
CREATE INDEX page_columns_idx_page_id ON page_columns (page_id);
CREATE INDEX pages_idx_dataset_id ON pages (dataset_id);

COMMIT;
