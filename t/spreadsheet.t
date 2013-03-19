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

    for my $ext (qw(xls xlsx csv)) {
        subtest "for $ext" => sub {

            my $filename = "${TEST_DATA_DIR}/basic.${ext}";
            my $TEST_XLS = IO::File->new($filename, 'r');

            my @constructor_tests = (
                [{filename => $filename},                     'filename',         ],
                [{filehandle => $TEST_XLS, filetype => $ext}, 'filehandle+parser',],
            );

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
        };
    }
};


subtest 'encoding' => sub {

    for my $ext (qw(xls xlsx csv)) {
        subtest "for $ext" => sub {

            ok my $js_utf8 = Judoon::Spreadsheet->new({
                filename => "${TEST_DATA_DIR}/encoding-utf8.${ext}"
            }), 'can open spreadsheet w/ utf8 chars';
            is $js_utf8->name, ($ext eq 'csv' ? 'IO' : 'sheet-üñîçø∂é'),
                '  ...name is correct';
            is_deeply [map {$_->{name}} @{ $js_utf8->fields }], ['ÜñîçøðÆ'],
                '  ...title is correct';
            is_deeply [map {$_->{shortname}} @{ $js_utf8->fields }],
                ['unicodae'], '  ...shortname is correct';
            is_deeply $js_utf8->data,
                [['Ellipsis…'],['‘Single Quotes’'],['“Double quotes”'],],
                    '  ...data is correct';

            return if ($ext eq 'xlsx');

            ok my $js_cp1252 = Judoon::Spreadsheet->new({
                filename => "${TEST_DATA_DIR}/encoding-cp1252.${ext}"
            }), 'can open spreadsheet w/ cp1252 chars';
            is $js_cp1252->name, ($ext eq 'csv' ? 'IO' : 'sheet-üñîçø∂é'),
                '  ...name is correct';
            is_deeply [map {$_->{name}} @{ $js_cp1252->fields }], ['ÜñîçøðÆ'],
                '  ...title is correct';
            is_deeply [map {$_->{shortname}} @{ $js_cp1252->fields }],
                ['unicodae'], '  ...shortname is correct';
            is_deeply $js_cp1252->data,
                [['Ellipsis…'],['‘Single Quotes’'],['“Double quotes”'],],
                    '  ...data is correct';
        };
    }

};


subtest troublesome => sub {
    for my $ext (qw(xls csv xlsx)) {
        subtest "for $ext" => sub {
            my $js_blank = Judoon::Spreadsheet->new({
                filename => "${TEST_DATA_DIR}/blank_header.${ext}",
            });
            is_deeply [map {$_->{name}} @{ $js_blank->fields }],
                [q{First Column}, q{(untitled column)}, q{Third Column},
                 q{(untitled column) (1)},],
                '  ...blank titles are correct';
            is_deeply [map {$_->{shortname}} @{ $js_blank->fields }],
                [q{first_column}, q{untitled}, q{third_column},
                 q{untitled_01},],
                '  ...blank sqlnames are correct';

            my $blank_data = $js_blank->data;
            is $blank_data->[3][0], '', 'first column space is blank';
            is $blank_data->[2][2], '', 'middle column is blank';
            is $blank_data->[2][3], '', 'final column is blank';
        };
    }
};

done_testing();
