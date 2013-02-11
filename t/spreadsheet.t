#!/usr/bin/env perl

use utf8;
use strict;
use warnings;
use autodie;

use Test::More;
use Test::Fatal;

use IO::File;
use Judoon::Spreadsheet;

my $TEST_DATA_DIR = 't/etc/data';

subtest 'basic' => sub {

    note("");
    my @test_files = qw(basic.xls basic.csv basic.xlsx); # basic.tab);
    for my $file (@test_files) {

        my $basic_fn = "${TEST_DATA_DIR}/${file}";
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


subtest 'encoding' => sub {

    for my $ext (qw(xls xlsx)) { # csv)) {
        subtest "for $ext" => sub {
            my $js_utf8;
            ok !exception {
                $js_utf8 = Judoon::Spreadsheet->new({
                    filename => "${TEST_DATA_DIR}/encoding-utf8.${ext}"
                });
            }, 'can open spreadsheet w/ utf8 chars';

            is $js_utf8->name, 'sheet-üñîçø∂é', 'got correctly-encoded name';
            is_deeply [map {$_->{name}} @{ $js_utf8->fields }], ['Üñîçøð€'],
                'correctly-encoded column title';
            is_deeply $js_utf8->data, [['Elipsis…'], ['ภาษาพูด'],],
                'utf8-encoded data good';
        };
    }

};


done_testing();
