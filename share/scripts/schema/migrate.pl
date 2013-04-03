#!/usr/bin/env perl

use strict;
use warnings;

use FindBin qw($Bin);
use lib qq{$Bin/../../../lib};

use DBIx::Class::Migration::Script;
use Judoon::Schema;

DBIx::Class::Migration::Script->run_with_options(
    schema => Judoon::Schema->connect('Judoon::Schema'),
);
