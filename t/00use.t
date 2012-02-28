#/usr/bin/env perl

use strict;
use warnings;

use Test::More;

BEGIN {
    my @modules = qw(
        Judoon::DB::User
        Judoon::DB::User::Schema
    );


    for my $module (@modules) {
        use_ok $module or BAIL_OUT;
    }
}

done_testing();
