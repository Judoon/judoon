#!/usr/bin/env perl

use strict;
use warnings;
use DBIx::Class::Migration::RunScript;

migrate {
    my $user_rs = shift->schema->resultset('User');
    $user_rs->create({login => 'felliott', name => 'Fitz Elliott'});
};
