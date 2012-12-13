#!/usr/bin/env perl

use strict;
use warnings;
use DBIx::Class::Migration::RunScript;
use DBIx::Class::Migration::RunScript::Trait::AuthenPassphrase;

use DateTime;

migrate {
    my $runscript = shift;

    my $schema = $runscript->schema;

    $schema->storage->dbh_do(
        sub {
            my ($storage, $dbh) = @_;

            my @user_schemas = map {$_->[0]} @{ $dbh->selectall_arrayref(q{
                SELECT nspname FROM pg_namespace
                WHERE nspname <> 'information_schema'
                   AND nspname <> 'public' AND nspname !~ E'^pg_'
            }) };

            use Data::Printer;
            warn "Schemas are: " . p(@user_schemas);

            # also set in Judoon::Schema::Result::User
            my $schema_prefix = 'user_';

            # need to rename schemas that already start with prefix first,
            # so that we don't have a collision with other usernames.
            # e.g:
            #  given schemas bob, user_bob:
            #   first,  user_bob => user_user_bob
            #   second, bob => user_bob
            my @could_conflict = grep {m/^$schema_prefix/} @user_schemas;
            my @wont_conflict  = grep {$_ !~ m/^$schema_prefix/} @user_schemas;
            for my $schema (@could_conflict, @wont_conflict) {
                $dbh->do("ALTER SCHEMA $schema RENAME TO ${schema_prefix}${schema}");
            }
        },
    );
};
