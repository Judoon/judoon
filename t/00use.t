#/usr/bin/env perl

use strict;
use warnings;

use Test::More;

BEGIN {
    my @modules = qw(
        Judoon::DB::User::Schema
        Judoon::Tmpl::Translator
        Judoon::Web
    );


    for my $module (@modules) {
        use_ok $module or BAIL_OUT;
    }
}

done_testing();
