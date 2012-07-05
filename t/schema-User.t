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
        [qw/username name active email_address password/],
        ['testuser', 'Test User', 1, 'testuser@example.com', 'testpass'],
    ],
], 'installed fixtures';


subtest 'Result::User' => sub {
    my $user_rs = ResultSet('User');

    is_result my $user = $user_rs->find({username => 'testuser'});


    $user->change_password('newpass');
    ok $user->password, 'newpass';

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

subtest 'ResultSet::User' => sub {
    my $user_rs = ResultSet('User');

    ok $user_rs->validate_username('boo'), 'validate simple username';
    ok !$user_rs->validate_username('b!!o'), 'reject invalid username';

    ok $user_rs->validate_password('boo'), 'validate simple password';
    ok $user_rs->validate_password('0q98347'), 'validate complex password';

    ok $user_rs->user_exists('testuser'), 'found existing user';
    ok !$user_rs->user_exists('fakeuser'), 'did not find fake user';

    my %newuser = (
        username => 'newuser', password => 'newuser', name => 'New User',
        email_address => 'newuser@example.com',
    );

    my @exceptions = (
        ['nousername', qr/no username was given/i, 'missing username',],
        ['nopassword', qr/no password was given/i, 'missing password',],
        ['badusername', qr/invalid username/i,     'invalid username',],
        ['dupeusername', qr/this username is already taken/i,  'duplicate username',],
    );
    my %create_user_exceptions = map {$_->[0] => {
        data => {%newuser}, exception => $_->[1], descr => $_->[2],
    }} @exceptions;

    delete $create_user_exceptions{nousername}->{data}{username};
    delete $create_user_exceptions{nopassword}->{data}{password};
    $create_user_exceptions{badusername}->{data}{username} = 'sdf@#sfdg';
    $create_user_exceptions{dupeusername}->{data}{username} = 'testuser';

    for my $i (values %create_user_exceptions) {
        like exception { $user_rs->create_user($i->{data}); },
            $i->{exception}, $i->{descr};
    }

    ok $user_rs->create_user(\%newuser), 'able to create new user';
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
