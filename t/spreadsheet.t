#/usr/bin/env perl

use strict;
use warnings;
use autodie;

use Test::More;
use Test::Fatal;

use IO::File;
use Judoon::Spreadsheet;

subtest 'pivot_data' => sub {

    # pivot_data()
    my $data     = [['boo'],['boo',1..4],['boo',5..8],['boo',9..12]];
    my $piv_data = [[1,5,9],[2,6,10],[3,7,11],[4,8,12]];
    my $pivoted  = Judoon::Spreadsheet::pivot_data($data, 4, 3);
    is_deeply $pivoted, $piv_data, 'pivot_data() pivots data!';


    my @fatals = (
        [[1,2,2],                 qr{'data' parameter .+ is not of type arrayref}i, q{data is not an arrayref}],
        [[[1],2,2],               qr{'data' parameter .+ is not of type arrayref\[arrayref\]}i, q{data is not an arrayref of arrayrefs}],
        [[[[1,2],[3,4]],undef,2], qr{'maxrow' parameter .+ is not of type Int}i, q{maxrow not defined}],
        [[[[1,2],[3,4]],'moo',2], qr{'maxrow' parameter .+ is not of type Int}i, q{maxrow is wrong type}],
        [[[[1,2],[3,4]],0,2],     qr{maxrow must be greater than 0}i, q{maxrow less than 1}],
        [[[[1,2],[3,4]],2,undef], qr{'maxcol' parameter .+ is not of type Int}i, q{maxcol not defined}],
        [[[[1,2],[3,4]],2,'moo'], qr{'maxcol' parameter .+ is not of type Int}i, q{maxcol is wrong type}],
        [[[[1,2],[3,4]],2,0],     qr{maxcol must be greater than 0}i, q{maxcol less than 1}],
    );

    for my $fatal (@fatals) {
        my ($args, $error, $descr) = @$fatal;
        like exception { Judoon::Spreadsheet::pivot_data(@$args); },
            $error, $descr;
    }

};


subtest 'read_spreadsheet' => sub {

    my $basic = {
        name => 'Sheet1', original => q{},  notes => q{},
        data => [
            ['Va Bene', 14, 'female'],
            ['Chloe',    2, 'female'],
            ['Grover',   8, 'male'  ],
            ['Chewie',   5, 'male'  ],
            ['Goochie',  1, 'female'],
        ],
        ds_columns => [
            {name => 'Name',   sort => 1, accession_type => q{}, url_root => q{},},
            {name => 'Age',    sort => 2, accession_type => q{}, url_root => q{},},
            {name => 'Gender', sort => 3, accession_type => q{}, url_root => q{},},
        ],
    };

    my @tests = (
        # file              type    data
        ['basic.xls',       undef,  $basic, ],
        ['basic.xls',       'xls',  $basic, ],
        ['basic.xlsx',      'xlsx', $basic, ],
        ['basic.csv',       'csv',  {%$basic,name=>'IO'}, ],
        ['troublesome.xls', '',     undef,   ],
    );


    for my $test (@tests) {
        my ($file, $type, $expected) = @$test;

        my $TEST_XLS = IO::File->new("t/etc/data/$file", 'r');
        ok my $data = Judoon::Spreadsheet::read_spreadsheet($TEST_XLS, $type),
            "can read spreadsheet $file";

        if ($expected) {
            is_deeply $data, $expected,
                "got expected data for $file with " . ($type // 'undef') . " parser";
        }
    }

};

done_testing();
