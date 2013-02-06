#!/usr/bin/env perl

use strict;
use warnings;
use autodie;

use Test::More;
use Test::Fatal;

use IO::File;
use Judoon::Spreadsheet;


subtest 'basic' => sub {

    my $test_file_root = 't/etc/data';
    for my $file (qw(basic.xls basic.xlsx)) { # basic.csv)) {

        my $basic_fn = "${test_file_root}/${file}";
        my ($ext) = ($basic_fn =~ m/\.(\w+)$/);
        my $TEST_XLS = IO::File->new($basic_fn, 'r');
        my $TEST_XLS_SLURP = IO::File->new($basic_fn, 'r');
        binmode $TEST_XLS_SLURP;
        my $file_contents = do {local $/ = undef; <$TEST_XLS_SLURP>; };

        my @constructor_tests = (
            [{filename => $basic_fn}, 'filename-only'],
            [{filehandle => $TEST_XLS, filetype => $ext}, 'filehandle+parser-only',],
            # [{filehandle => $TEST_XLS}, 'filehandle-only'],
            # [{content => $file_contents}, 'contents-only'],
        );

        for my $cons_test (@constructor_tests) {
            ok my $js = Judoon::Spreadsheet->new($cons_test->[0]),
                "new() via $cons_test->[1] for $ext";
            is $js->name, ($ext =~ m/xls/ ? 'Dog Roster' : 'Sheet1'),
                '  ...basic sanity test';
        }
    }
};

done_testing();
