#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;


# Judoon::Web uses HTML::String::TT, which warns if loaded after
# Template.  Make sure we load Judoon::Web before any other modules.
BEGIN {
    my @modules = qw(
        Judoon::Web

        Judoon::Schema
        Judoon::Tmpl
        Judoon::SiteLinker
        Judoon::Spreadsheet
        Judoon::Standalone
    );


    for my $module (@modules) {
        use_ok $module or BAIL_OUT;
    }
}

done_testing();
