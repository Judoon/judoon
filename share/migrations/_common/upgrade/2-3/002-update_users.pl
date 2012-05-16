#!/usr/bin/env perl

use strict;
use warnings;
use DBIx::Class::Migration::RunScript;

migrate {
    my $schema = shift->schema;
    $schema->resultset('Role')->populate([
        ['name'],
        ['admin'],
    ]);

    my $admin = $schema->resultset('Role')->find({name => 'admin'});
    $schema->resultset('User')->create({
        active        => "y",
        username      => 'fge7z',
        password      => 'moomoo',
        name          => 'Fitz Elliott',
        email_address => 'felliott@virginia.edu',
    })->add_to_roles($admin);
};
