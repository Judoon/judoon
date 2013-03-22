#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Pod::Coverage;

plan skip_all => 'set TEST_POD to enable this test' unless $ENV{TEST_POD};

my @modules = sort {$a cmp $b}
    all_modules(qw(lib/Judoon lib/DBIx lib/Catalyst));
for my $module (@modules) {
    pod_coverage_ok($module, {
        coverage_class => 'Pod::Coverage::TrustPod',
    });
}
