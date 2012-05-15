#/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::DBIx::Class {
    schema_class => 'Judoon::DB::User::Schema',
};
use Test::Fatal;


use Data::Printer;


fixtures_ok [
    User => [
        [qw/login name/],
        ['testuser', 'Test User'],
    ],
], 'installed fixtures';


subtest 'Result::User' => sub {
    my $user_rs = ResultSet('User');

    is_result my $user = $user_rs->find({login => 'testuser'});

    # pivot_data()
    my $data     = [['boo'],['boo',1..4],['boo',5..8],['boo',9..12]];
    #diag "Data: " . p($data);
    my $piv_data = [[1,5,9],[2,6,10],[3,7,11],[4,8,12]];
    my $pivoted  = $user->pivot_data($data, 4, 3);
    #diag "Pivoted is: " . p($pivoted);
    is_deeply $pivoted, $piv_data, 'pivot_data() pivots data!';


    # import_data()
    open my $TEST_XLS, '<', 't/etc/data/test1.xls'
        or die "Can't open test spreadsheet: $!";
    is_result my $dataset = $user->import_data($TEST_XLS);
    close $TEST_XLS;
};


subtest 'Result::Dataset' => sub {
    pass 'placeholder test';
};

subtest 'Result::DatasetColumn' => sub {
    my $ds_column_rs = ResultSet('DatasetColumn');
    my $ds_column = $ds_column_rs->first;

    my $dataset = $ds_column->dataset;
    my $new_ds_col = $dataset->create_related('ds_columns', {
        name => 'Test Column', sort => 99,
        is_accession => 1, accession_type => q{flybase_id},
        is_url => 0, url_root => q{},
    });
    is $new_ds_col->shortname, 'test_column', 'auto shortname works';
    is $new_ds_col->linkset->[0]{value}, 'flybase', 'linkset works for accession';

    my $new_ds_col2 = $dataset->create_related('ds_columns', {
        name => 'Test Column 2', shortname => 'moo', sort => 99,
        is_accession => 0, accession_type => q{},
        is_url => 1, url_root => q{http://google.com/},
    });
    is $new_ds_col2->shortname, 'moo',
        "auto shortname doesn't overwrite provided shortname";
    is $new_ds_col2->linkset->[0], 'something else?', 'BOGUS TEST: linkset works for url';
};



done_testing();
