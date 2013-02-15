#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

BEGIN {
    my @modules = qw(
        Judoon::Schema
        Judoon::Tmpl
        Judoon::SiteLinker
        Judoon::Spreadsheet
        Judoon::Standalone
        Judoon::Web
    );


    for my $module (@modules) {
        use_ok $module or BAIL_OUT;
    }
}

done_testing();
