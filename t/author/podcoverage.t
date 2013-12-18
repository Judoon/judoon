#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Pod::Coverage;

# Judoon::Web uses HTML::String::TT, which warns if loaded after
# Template.  Make sure we load Judoon::Web before any other modules.
my @modules = grep {$_ ne 'Judoon::Web'} sort {$a cmp $b}
    all_modules(qw(lib/Judoon lib/DBIx));
for my $module ('Judoon::Web', @modules) {
    pod_coverage_ok($module, {
        coverage_class => 'Pod::Coverage::TrustPod',
    });
}

done_testing();
