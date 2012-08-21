#/usr/bin/env perl

use strict;
use warnings;
use autodie;

use Test::More;
use Test::Fatal;

use IO::File;
use Judoon::Spreadsheet;


subtest 'basic' => sub {

    ok my $js_filename   = Judoon::Spreadsheet->new({filename => 't/etc/data/basic.xls'});

    my $TEST_XLS = IO::File->new("t/etc/data/basic.xls", 'r');
    ok my $js_filehandle = Judoon::Spreadsheet->new({filehandle => $TEST_XLS});

    ok my $js_filehandle2 = Judoon::Spreadsheet->new({filehandle => $TEST_XLS, filetype => 'xls'});

    binmode $TEST_XLS;
    my $file_contents = do {local $/ = undef; <$TEST_XLS>; };
    ok my $js_contents = Judoon::Spreadsheet->new({content => $file_contents});

    my @tests = (
        # file              type    data
        ['basic.xls',       undef,  ], # $basic, ],
        ['basic.xls',       'xls',  ], # $basic, ],
        ['basic.xlsx',      'xlsx', ], # $basic, ],
        ['basic.csv',       'csv',  ], # {%$basic,name=>'IO'}, ],
        ['troublesome.xls', '',     ], # undef,   ],
    );

    for my $test (@tests) {
        my ($file, $type, $expected) = @$test;

        my $TEST_XLS = IO::File->new("t/etc/data/$file", 'r');
        ok my $spreadsheet = Judoon::Spreadsheet->new({
            filehandle => $TEST_XLS, filetype => $type,
        }),
            "can read spreadsheet $file";
    }

};

done_testing();
