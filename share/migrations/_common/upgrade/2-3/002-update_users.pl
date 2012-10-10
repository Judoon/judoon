#!/usr/bin/env perl

use strict;
use warnings;
use DBIx::Class::Migration::RunScript;
use DBIx::Class::Migration::RunScript::Trait::AuthenPassphrase;

use DateTime;

migrate {
    my $runscript = shift;

    my $schema = $runscript->schema;
    $schema->resultset('Role')->populate([
        ['name'],
        ['admin'],
    ]);
    my $admin = $schema->resultset('Role')->find({name => 'admin'});

    my $passphrase_args = {
        passphrase       => 'rfc2307',
        passphrase_class => 'BlowfishCrypt',
        passphrase_args  => {
            cost        => 8,
            salt_random => 20,
        },
    };
    my $encoded = $runscript->authen_passphrase(
        $passphrase_args, 'moomoomoo',
    );

    $schema->resultset('User')->find({username => 'felliott'})->update({
        password         => $encoded,
        password_expires => DateTime->now,
        name             => 'Fitz Elliott',
        email_address    => 'felliott@virginia.edu',
    })->add_to_roles($admin);
};
