-- Convert schema '/Users/fge7z/code/work/judoon/share/scripts/schema/../../../share/migrations/_source/deploy/17/001-auto.yml' to '/Users/fge7z/code/work/judoon/share/scripts/schema/../../../share/migrations/_source/deploy/18/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE "tokens" (
  "id" serial NOT NULL,
  "value" text NOT NULL,
  "expires" timestamp with time zone NOT NULL,
  "action" text NOT NULL,
  "user_id" integer NOT NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT "token_value_is_uniq" UNIQUE ("value"),
  CONSTRAINT "user_action_is_uniq" UNIQUE ("user_id", "action")
);
CREATE INDEX "tokens_idx_user_id" on "tokens" ("user_id");

;
ALTER TABLE "tokens" ADD CONSTRAINT "tokens_fk_user_id" FOREIGN KEY ("user_id")
  REFERENCES "users" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;

COMMIT;

