#!/usr/bin/env perl

use strict;
use warnings;
use DBIx::Class::Migration::RunScript;

use DateTime;

migrate {
    my $schema = shift->schema;
    $schema->resultset('Role')->populate([
        ['name'],
        ['admin'],
    ]);

    my $admin = $schema->resultset('Role')->find({name => 'admin'});
    $schema->resultset('User')->find({username => 'fge7z'})->update({
        password         => 'moomoo',
        password_expires => DateTime->now,
        name             => 'Fitz Elliott',
        email_address    => 'felliott@virginia.edu',
    })->add_to_roles($admin);
};
