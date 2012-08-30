-- 
-- Created by SQL::Translator::Producer::SQLite
-- Created on Tue Aug 28 16:20:45 2012
-- 

;
BEGIN TRANSACTION;
--
-- Table: dataset_columns
--
CREATE TABLE dataset_columns (
  id INTEGER PRIMARY KEY NOT NULL,
  dataset_id integer NOT NULL,
  name text NOT NULL,
  sort integer NOT NULL,
  is_accession integer NOT NULL DEFAULT 0,
  accession_type text NOT NULL,
  is_url integer NOT NULL DEFAULT 0,
  url_root text NOT NULL,
  shortname text,
  FOREIGN KEY (dataset_id) REFERENCES datasets(id) ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE INDEX dataset_columns_idx_dataset_id ON dataset_columns (dataset_id);
--
-- Table: datasets
--
CREATE TABLE datasets (
  id INTEGER PRIMARY KEY NOT NULL,
  user_id integer NOT NULL,
  name text NOT NULL,
  notes text NOT NULL,
  original text NOT NULL,
  tablename text NOT NULL,
  nbr_rows integer NOT NULL,
  nbr_columns integer NOT NULL,
  permission text NOT NULL DEFAULT 'private',
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE INDEX datasets_idx_user_id ON datasets (user_id);
--
-- Table: page_columns
--
CREATE TABLE page_columns (
  id INTEGER PRIMARY KEY NOT NULL,
  page_id integer NOT NULL,
  title text NOT NULL,
  template text NOT NULL,
  FOREIGN KEY (page_id) REFERENCES pages(id) ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE INDEX page_columns_idx_page_id ON page_columns (page_id);
--
-- Table: pages
--
CREATE TABLE pages (
  id INTEGER PRIMARY KEY NOT NULL,
  dataset_id integer NOT NULL,
  title text NOT NULL,
  preamble text NOT NULL,
  postamble text NOT NULL,
  permission text NOT NULL DEFAULT 'private',
  FOREIGN KEY (dataset_id) REFERENCES datasets(id) ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE INDEX pages_idx_dataset_id ON pages (dataset_id);
--
-- Table: roles
--
CREATE TABLE roles (
  id INTEGER PRIMARY KEY NOT NULL,
  name text NOT NULL
);
CREATE UNIQUE INDEX name_unique ON roles (name);
--
-- Table: user_roles
--
CREATE TABLE user_roles (
  user_id integer NOT NULL,
  role_id integer NOT NULL,
  PRIMARY KEY (user_id, role_id),
  FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE INDEX user_roles_idx_role_id ON user_roles (role_id);
CREATE INDEX user_roles_idx_user_id ON user_roles (user_id);
--
-- Table: users
--
CREATE TABLE users (
  id INTEGER PRIMARY KEY NOT NULL,
  active char(1) NOT NULL,
  username text NOT NULL,
  password text NOT NULL,
  password_expires timestamp,
  name text NOT NULL,
  email_address text NOT NULL,
  phone_number text,
  mail_address text
);
CREATE UNIQUE INDEX username_unique ON users (username);
COMMIT