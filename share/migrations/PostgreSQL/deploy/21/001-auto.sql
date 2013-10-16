-- 
-- Created by SQL::Translator::Producer::PostgreSQL
-- Created on Wed Oct 16 13:27:19 2013
-- 
;
--
-- Table: dataset_columns.
--
CREATE TABLE "dataset_columns" (
  "id" serial NOT NULL,
  "dataset_id" integer NOT NULL,
  "name" text NOT NULL,
  "shortname" text,
  "sort" integer NOT NULL,
  "data_type" text NOT NULL,
  "created" timestamp with time zone NOT NULL,
  "modified" timestamp with time zone NOT NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT "dataset_id_name_unique" UNIQUE ("dataset_id", "name"),
  CONSTRAINT "dataset_id_shortname_unique" UNIQUE ("dataset_id", "shortname")
);
CREATE INDEX "dataset_columns_idx_dataset_id" on "dataset_columns" ("dataset_id");
CREATE INDEX "dataset_columns_idx_data_type" on "dataset_columns" ("data_type");

;
--
-- Table: datasets.
--
CREATE TABLE "datasets" (
  "id" serial NOT NULL,
  "user_id" integer NOT NULL,
  "name" text NOT NULL,
  "description" text NOT NULL,
  "original" text NOT NULL,
  "tablename" text NOT NULL,
  "nbr_rows" integer NOT NULL,
  "nbr_columns" integer NOT NULL,
  "permission" text DEFAULT 'private' NOT NULL,
  "created" timestamp with time zone NOT NULL,
  "modified" timestamp with time zone NOT NULL,
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
  "sort" integer NOT NULL,
  "created" timestamp with time zone NOT NULL,
  "modified" timestamp with time zone NOT NULL,
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
  "created" timestamp with time zone NOT NULL,
  "modified" timestamp with time zone NOT NULL,
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
  CONSTRAINT "roles_name" UNIQUE ("name")
);

;
--
-- Table: tokens.
--
CREATE TABLE "tokens" (
  "id" serial NOT NULL,
  "value" text NOT NULL,
  "expires" timestamp with time zone NOT NULL,
  "action" text NOT NULL,
  "user_id" integer NOT NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT "tokens_value" UNIQUE ("value")
);
CREATE INDEX "tokens_idx_user_id" on "tokens" ("user_id");

;
--
-- Table: tt_dscolumn_datatypes.
--
CREATE TABLE "tt_dscolumn_datatypes" (
  "data_type" text NOT NULL,
  PRIMARY KEY ("data_type")
);

;
--
-- Table: user_roles.
--
CREATE TABLE "user_roles" (
  "role_id" integer NOT NULL,
  "user_id" integer NOT NULL,
  PRIMARY KEY ("role_id", "user_id")
);
CREATE INDEX "user_roles_idx_role_id" on "user_roles" ("role_id");
CREATE INDEX "user_roles_idx_user_id" on "user_roles" ("user_id");

;
--
-- Table: users.
--
CREATE TABLE "users" (
  "id" serial NOT NULL,
  "username" character varying(40) NOT NULL,
  "password" text NOT NULL,
  "password_expires" timestamp,
  "name" text NOT NULL,
  "email_address" text NOT NULL,
  "active" boolean DEFAULT true NOT NULL,
  "created" timestamp with time zone NOT NULL,
  "modified" timestamp with time zone NOT NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT "users_email_address" UNIQUE ("email_address"),
  CONSTRAINT "users_username" UNIQUE ("username")
);

;
--
-- Foreign Key Definitions
--

;
ALTER TABLE "dataset_columns" ADD CONSTRAINT "dataset_columns_fk_dataset_id" FOREIGN KEY ("dataset_id")
  REFERENCES "datasets" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "dataset_columns" ADD CONSTRAINT "dataset_columns_fk_data_type" FOREIGN KEY ("data_type")
  REFERENCES "tt_dscolumn_datatypes" ("data_type") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

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
ALTER TABLE "tokens" ADD CONSTRAINT "tokens_fk_user_id" FOREIGN KEY ("user_id")
  REFERENCES "users" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "user_roles" ADD CONSTRAINT "user_roles_fk_role_id" FOREIGN KEY ("role_id")
  REFERENCES "roles" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "user_roles" ADD CONSTRAINT "user_roles_fk_user_id" FOREIGN KEY ("user_id")
  REFERENCES "users" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
