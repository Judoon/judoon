#/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::DBIx::Class {
    schema_class => 'Judoon::DB::User::Schema',
};
use Test::Fatal;


use Data::Printer;
use Judoon::Tmpl::Factory ();


fixtures_ok [
    User => [
        [qw/username name active email_address password/],
        ['testuser', 'Test User', 1, 'testuser@example.com', 'testpass'],
    ],
], 'installed fixtures';


subtest 'Result::User' => sub {
    my $user_rs = ResultSet('User');
    is_result my $user = $user_rs->find({username => 'testuser'});

    $user->change_password('testuser');
    ok $user->check_password('testuser'), 'password successfully set';
    like exception { $user->change_password('moo'); }, qr{invalid password}i,
        'Cant set invalid password';

    # pivot_data()
    my $data     = [['boo'],['boo',1..4],['boo',5..8],['boo',9..12]];
    my $piv_data = [[1,5,9],[2,6,10],[3,7,11],[4,8,12]];
    my $pivoted  = $user->pivot_data($data, 4, 3);
    is_deeply $pivoted, $piv_data, 'pivot_data() pivots data!';


    # import_data()
    like exception { $user->import_data(); },
        qr{import_data\(\) needs a filehandle}i, 'import_data() dies w/o fh';

    open my $TEST_XLS, '<', 't/etc/data/test1.xls'
        or die "Can't open test spreadsheet: $!";
    is_result $user->import_data($TEST_XLS);
    close $TEST_XLS;

    open $TEST_XLS, '<', 't/etc/data/troublesome.xls'
        or die "Can't open test spreadsheet: $!";
    is_result $user->import_data($TEST_XLS);
    close $TEST_XLS;
};

subtest 'ResultSet::User' => sub {
    my $user_rs = ResultSet('User');

    ok $user_rs->validate_username('boo'),   'validate simple username';
    ok !$user_rs->validate_username('b!!o'), 'reject invalid username';
    ok !$user_rs->validate_username(''),     'reject empty username';
    ok !$user_rs->validate_username(),       'reject undef username';

    ok $user_rs->validate_password('boobooboo'),   'validate simple password';
    ok $user_rs->validate_password('n(&*M09{}}#'), 'validate complex password';
    ok !$user_rs->validate_password(),             'reject undefined password';
    ok !$user_rs->validate_password('boo'),        'reject too short password';

    ok $user_rs->user_exists('testuser'), 'found existing user';
    ok !$user_rs->user_exists('fakeuser'), 'did not find fake user';

    my %newuser = (
        username => 'newuser', password => 'iamnewuser', name => 'New User',
        email_address => 'newuser@example.com',
    );

    my @exceptions = (
        ['nousername', qr/no username was given/i,  'missing username',],
        ['nopassword', qr/no password was given/i,  'missing password',],
        ['badusername', qr/invalid username/i,      'invalid username',],
        ['badpassword', qr/password is not valid/i, 'invalid password',],
        ['dupeusername', qr/this username is already taken/i,  'duplicate username',],
    );
    my %create_user_exceptions = map {$_->[0] => {
        data => {%newuser}, exception => $_->[1], descr => $_->[2],
    }} @exceptions;

    delete $create_user_exceptions{nousername}->{data}{username};
    delete $create_user_exceptions{nopassword}->{data}{password};
    $create_user_exceptions{badusername}->{data}{username} = 'sdf@#sfdg';
    $create_user_exceptions{badpassword}->{data}{password} = 'short';
    $create_user_exceptions{dupeusername}->{data}{username} = 'testuser';

    for my $i (values %create_user_exceptions) {
        like exception { $user_rs->create_user($i->{data}); },
            $i->{exception}, $i->{descr};
    }

    ok $user_rs->create_user(\%newuser), 'able to create new user';

    $newuser{username} = 'neweruser';
    $newuser{active}   = 0;
    ok my $inactive = $user_rs->create_user(\%newuser), 'create new user (explicitly not active)';
    ok !$inactive->active, 'inactive user is inactive';
};

subtest 'Result::Dataset' => sub {
    my $dataset = ResultSet('Dataset')->first;
    ok $dataset->create_basic_page(), 'create_basic_page() works';

    is $dataset->nbr_columns, 3, 'nbr_columns is three';
    is $dataset->nbr_rows, 5, 'nbr_rows is five';

    # mutating methods, create new dataset
    my $user = ResultSet('User')->first;
    open my $TEST_XLS, '<', 't/etc/data/test1.xls'
        or die "Can't open test spreadsheet: $!";
    my $mutable_ds = $user->import_data($TEST_XLS);
    close $TEST_XLS;

    my @delete_failures = (
        [[1,2,'boo'], qr{positive integer}i, 'string', ],
        [[1,2,undef], qr{positive integer}i, 'undef',  ],
        [[1,0,2],     qr{1-indexed}i,        'zero',   ],
        [[100,2,3],   qr{larger than the number of columns}i, 'too big', ],
    );
    for my $del_failure (@delete_failures) {
        my ($cols, $error, $descr) = @$del_failure;
        like exception { $mutable_ds->delete_data_columns(@$cols); },
            $error, $descr;
    }

    $mutable_ds->delete_data_columns(3,1);
    is $mutable_ds->nbr_rows, 5, 'still five rows';
    is $mutable_ds->nbr_columns, 1, 'now just 1 row';
    is_deeply $mutable_ds->data, [[14],[2],[8],[5],[1]], 'Data is as expected';
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

    ok my $ds_col3 = $dataset->create_related('ds_columns', {
        name => q{}, sort => 98, is_accession => 0, accession_type => q{},
        is_url => 0, url_root => q{},
    }), 'can create column w/ empty name';
    is $ds_col3->shortname, 'nothing', 'shortname defaulted correctly';
    is_deeply $ds_col3->linkset, [], 'unannotated column gives empty linkset';

    ok my $ds_col4 = $dataset->create_related('ds_columns', {
        name => q{#$*^(}, sort => 97, is_accession => 0, accession_type => q{},
        is_url => 1, url_root => q{http://google.com/?q=},
    }), 'can create column w/ non-ascii name';
    is $ds_col4->shortname, '_____', 'shortname defaulted correctly';
    ok $ds_col4->linkset, 'can get linkset for url';

};


subtest 'Result::Page' => sub {
    my $page = ResultSet('Page')->first;

    is $page->nbr_columns, 3, '::nbr_columns is correct';
    is $page->nbr_rows, 5,    '::nbr_rows is correct';
};


subtest 'Result::PageColumn' => sub {
    my $page_column = ResultSet('PageColumn')->first;

    ok $page_column->template_to_jquery,     'can produce jquery';
    ok $page_column->template_to_webwidgets, 'can produce webwidgets';
    ok $page_column->template_to_objects,    'can produce objects';

    my $newline = Judoon::Tmpl::Factory::new_newline_node();
    ok $page_column->set_template($newline), 'can set template...';
    my @objects = $page_column->template_to_objects;
    ok @objects == 1 && ref($objects[0]) eq 'Judoon::Tmpl::Node::Newline',
        '  ...and get correct objects back';
};

done_testing();
