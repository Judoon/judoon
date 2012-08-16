#/usr/bin/env perl

use strict;
use warnings;

use Test::More;

BEGIN {
    my @modules = qw(
        Judoon::DataStore::SQLite
        Judoon::DB::DataStore::Schema
        Judoon::DB::User::Schema
        Judoon::Tmpl::Translator
        Judoon::SiteLinker
        Judoon::Spreadsheet
        Judoon::Web
    );


    for my $module (@modules) {
        use_ok $module or BAIL_OUT;
    }
}

done_testing();
