#!/usr/bin/env perl

use strict;
use warnings;
use feature ':5.14';

use DBIx::RunSQL;
use DBIx::Class::Schema::Loader 'make_schema_at';
use FindBin qw($Bin);

my $test_dbh = DBIx::RunSQL->create(
    dsn     => 'dbi:SQLite:dbname=:memory:',
    sql     => "$Bin/db/schema.sql",
    force   => 1,
    #verbose => 1,
);

make_schema_at(
    'Judoon::DB::User::Schema',
    {
        # components     => [ 'InflateColumn::DateTime', 'TimeStamp', ],
        # debug          => 1,
        dump_directory => "$Bin/../../../lib",
        use_moose      => 1,
        exclude        => qr/^dbix_class/,
        # rel_name_map => {
        #     DatasetColumn => { dataset_column => 'ds_column', },
        # },
        overwrite_modifications => 1,
    },
    [ sub { $test_dbh }, {} ]
);
