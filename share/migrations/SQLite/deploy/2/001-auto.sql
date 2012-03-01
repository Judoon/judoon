-- 
-- Created by SQL::Translator::Producer::SQLite
-- Created on Wed Feb 29 16:40:03 2012
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
  FOREIGN KEY(dataset_id) REFERENCES datasets(id)
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
  data text NOT NULL,
  FOREIGN KEY(user_id) REFERENCES users(id)
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
  FOREIGN KEY(page_id) REFERENCES pages(id)
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
  FOREIGN KEY(dataset_id) REFERENCES datasets(id)
);
CREATE INDEX pages_idx_dataset_id ON pages (dataset_id);
--
-- Table: users
--
CREATE TABLE users (
  id INTEGER PRIMARY KEY NOT NULL,
  login text NOT NULL,
  name text NOT NULL
);
CREATE UNIQUE INDEX login_unique ON users (login);
COMMIT