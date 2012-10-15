-- 
-- Created by SQL::Translator::Producer::PostgreSQL
-- Created on Mon Oct 15 13:55:42 2012
-- 
;
--
-- Table: dataset_columns.
--
CREATE TABLE "dataset_columns" (
  "id" serial NOT NULL,
  "dataset_id" integer NOT NULL,
  "name" text NOT NULL,
  "sort" integer NOT NULL,
  "is_accession" integer DEFAULT 0 NOT NULL,
  "accession_type" text NOT NULL,
  "is_url" integer DEFAULT 0 NOT NULL,
  "url_root" text NOT NULL,
  "shortname" text,
  PRIMARY KEY ("id"),
  CONSTRAINT "dataset_id_shortname_unique" UNIQUE ("dataset_id", "shortname")
);
CREATE INDEX "dataset_columns_idx_dataset_id" on "dataset_columns" ("dataset_id");

;
--
-- Table: datasets.
--
CREATE TABLE "datasets" (
  "id" serial NOT NULL,
  "user_id" integer NOT NULL,
  "name" text NOT NULL,
  "notes" text NOT NULL,
  "original" text NOT NULL,
  "tablename" text NOT NULL,
  "nbr_rows" integer NOT NULL,
  "nbr_columns" integer NOT NULL,
  "permission" text DEFAULT 'private' NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "datasets_idx_user_id" on "datasets" ("user_id");

;
--
-- Table: page_columns.
--
CREATE TABLE "page_columns" (
  "id" serial NOT NULL,
  "page_id" integer NOT NULL,
  "title" text NOT NULL,
  "template" text NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "page_columns_idx_page_id" on "page_columns" ("page_id");

;
--
-- Table: pages.
--
CREATE TABLE "pages" (
  "id" serial NOT NULL,
  "dataset_id" integer NOT NULL,
  "title" text NOT NULL,
  "preamble" text NOT NULL,
  "postamble" text NOT NULL,
  "permission" text DEFAULT 'private' NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "pages_idx_dataset_id" on "pages" ("dataset_id");

;
--
-- Table: roles.
--
CREATE TABLE "roles" (
  "id" serial NOT NULL,
  "name" text NOT NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT "name_unique" UNIQUE ("name")
);

;
--
-- Table: user_roles.
--
CREATE TABLE "user_roles" (
  "user_id" integer NOT NULL,
  "role_id" integer NOT NULL,
  PRIMARY KEY ("user_id", "role_id")
);
CREATE INDEX "user_roles_idx_role_id" on "user_roles" ("role_id");
CREATE INDEX "user_roles_idx_user_id" on "user_roles" ("user_id");

;
--
-- Table: users.
--
CREATE TABLE "users" (
  "id" serial NOT NULL,
  "active" character(1) NOT NULL,
  "username" text NOT NULL,
  "password" text NOT NULL,
  "password_expires" timestamp,
  "name" text NOT NULL,
  "email_address" text NOT NULL,
  "phone_number" text,
  "mail_address" text,
  PRIMARY KEY ("id"),
  CONSTRAINT "username_unique" UNIQUE ("username")
);

;
--
-- Foreign Key Definitions
--

;
ALTER TABLE "dataset_columns" ADD CONSTRAINT "dataset_columns_fk_dataset_id" FOREIGN KEY ("dataset_id")
  REFERENCES "datasets" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "datasets" ADD CONSTRAINT "datasets_fk_user_id" FOREIGN KEY ("user_id")
  REFERENCES "users" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "page_columns" ADD CONSTRAINT "page_columns_fk_page_id" FOREIGN KEY ("page_id")
  REFERENCES "pages" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "pages" ADD CONSTRAINT "pages_fk_dataset_id" FOREIGN KEY ("dataset_id")
  REFERENCES "datasets" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "user_roles" ADD CONSTRAINT "user_roles_fk_role_id" FOREIGN KEY ("role_id")
  REFERENCES "roles" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "user_roles" ADD CONSTRAINT "user_roles_fk_user_id" FOREIGN KEY ("user_id")
  REFERENCES "users" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

