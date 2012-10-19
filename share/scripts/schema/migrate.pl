#!/usr/bin/env perl

use strict;
use warnings;

use FindBin qw($Bin);
use lib qq{$Bin/../../../lib};

use DBIx::Class::Migration::Script;
use Judoon::Web;

DBIx::Class::Migration::Script->run_with_options(
    schema => Judoon::Web->model('User')->schema,
);
