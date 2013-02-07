#!/usr/bin/env perl

use strict;
use warnings;
use autodie;

use Test::More;
use Test::Fatal;

use IO::File;
use Judoon::Spreadsheet;


subtest 'basic' => sub {

    note("");
    my $test_file_root = 't/etc/data';
    my @test_files = qw(basic.xls basic.xlsx basic.csv); # basic.tab);
    for my $file (@test_files) {

        my $basic_fn = "${test_file_root}/${file}";
        my ($ext) = ($basic_fn =~ m/\.(\w+)$/);
        $ext = 'csv' if ($ext eq 'tab');
        my $TEST_XLS = IO::File->new($basic_fn, 'r');

        my @constructor_tests = (
            [{filename => $basic_fn},                     'filename',         ],
            [{filehandle => $TEST_XLS, filetype => $ext}, 'filehandle+parser',],
        );

        diag "Running $ext...";
        for my $cons_test (@constructor_tests) {
            ok my $js = Judoon::Spreadsheet->new($cons_test->[0]),
                "  new() via $cons_test->[1] for $ext";
            is $js->name, ($ext =~ m/xls/ ? 'Dog Roster' : 'IO'),
                '    ...correct name';
            is $js->nbr_rows, 5, '    ...correct number of rows';
            is $js->nbr_columns, 3, '    ...correct number of columns';
            is_deeply [map {$_->{name}} @{$js->fields}],
                [qw(Name Age Gender)], '    ...correct field names';
            is_deeply [map {$_->{type}} @{$js->fields}],
                [qw(text numeric text)], '    ...correct field types';
            is_deeply $js->data, [
                ['Va Bene', 14, 'female'],
                ['Chloe',    2, 'female'],
                ['Grover',   8, 'male'  ],
                ['Chewie',   5, 'male'  ],
                ['Goochie',  1, 'female'],
            ], '    ...correct data';
        }
    }
};

done_testing();
