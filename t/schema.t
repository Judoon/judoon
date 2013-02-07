#!/usr/bin/env perl

use strict;
use warnings;

use lib q{t/lib};

use Test::More;
use Test::Fatal;
use Test::JSON;
use t::DB;

use Data::Printer;
use Judoon::Spreadsheet;
use Judoon::Tmpl;
use Spreadsheet::Read;

sub ResultSet { return t::DB::get_schema()->resultset($_[0]); }
sub is_result { return isa_ok $_[0], 'DBIx::Class'; }


subtest 'Result::User' => sub {
    my $user_rs = ResultSet('User');
    is_result my $user = $user_rs->find({username => 'testuser'});

    $user->change_password('testuser');
    ok $user->check_password('testuser'), 'password successfully set';
    like exception { $user->change_password('moo'); }, qr{invalid password}i,
        'Cant set invalid password';

    # import_data()
    open my $TEST_XLS, '<', 't/etc/data/basic.xls'
        or die "Can't open test spreadsheet: $!";
    like exception { $user->import_data(); },
        qr{import_data\(\) needs a filehandle}i, 'import_data() dies w/o fh';
    like exception { $user->import_data($TEST_XLS); },
        qr{import_data\(\) needs a filetype}i, 'import_data() dies w/o filetype';
    is_result $user->import_data($TEST_XLS, 'xls');
    close $TEST_XLS;

    # import_data_by_filename()
    is_result $user->import_data_by_filename('t/etc/data/basic.xls');

};

subtest 'ResultSet::User' => sub {
    my $user_rs = ResultSet('User');

    ok $user_rs->validate_username('boo'),     'validate simple username';
    ok !$user_rs->validate_username('b!!o'),   'reject invalid username';
    ok !$user_rs->validate_username(''),       'reject empty username';
    ok !$user_rs->validate_username(),         'reject undef username';
    ok !$user_rs->validate_username('b' x 50), 'reject too-long username';

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
        ['nousername', qr/no username was given/i,       'missing username',],
        ['nopassword', qr/no password was given/i,       'missing password',],
        ['noemail',    qr/no email address was given/i,  'missing email',],
        ['badusername', qr/invalid username/i,      'invalid username',],
        ['badpassword', qr/password is not valid/i, 'invalid password',],
        ['dupeusername', qr/this username is already taken/i,  'duplicate username',],
        ['dupeemail',    qr/another account already has this email address/i,  'duplicate email_address',],
    );
    my %create_user_exceptions = map {$_->[0] => {
        data => {%newuser}, exception => $_->[1], descr => $_->[2],
    }} @exceptions;

    delete $create_user_exceptions{nousername}->{data}{username};
    delete $create_user_exceptions{nopassword}->{data}{password};
    delete $create_user_exceptions{noemail}->{data}{email_address};
    $create_user_exceptions{badusername}->{data}{username} = 'sdf@#sfdg';
    $create_user_exceptions{badpassword}->{data}{password} = 'short';
    $create_user_exceptions{dupeusername}->{data}{username} = 'testuser';
    $create_user_exceptions{dupeemail}->{data}{email_address} = 'testuser@example.com';

    for my $i (values %create_user_exceptions) {
        like exception { $user_rs->create_user($i->{data}); },
            $i->{exception}, $i->{descr};
    }

    ok $user_rs->create_user(\%newuser), 'able to create new user';

    @newuser{qw(username email_address active)}
        = qw(neweruser neweruser@example.com 0);
    ok my $inactive = $user_rs->create_user(\%newuser),
        'create new user (explicitly not active)';
    ok !$inactive->active, 'inactive user is inactive';
};

subtest 'Result::Dataset' => sub {
    my $dataset = ResultSet('Dataset')->first;
    ok $dataset->create_basic_page(), 'create_basic_page() works';

    is $dataset->nbr_columns, 3, 'nbr_columns is three';
    is $dataset->nbr_rows, 5, 'nbr_rows is five';


    # test importing from spreadsheets
    my $xls_ds_data = [
        ['Va Bene', 14, 'female'],
        ['Chloe',    2, 'female'],
        ['Grover',   8, 'male'  ],
        ['Chewie',   5, 'male'  ],
        ['Goochie',  1, 'female'],
    ];
    my $xls_cols = [
        {name => 'Name',   sort => 1, },
        {name => 'Age',    sort => 2, },
        {name => 'Gender', sort => 3, },
    ];

    # mutating methods, create new dataset
    my $user = ResultSet('User')->find({username => 'testuser'});
    my $mutable_ds = $user->import_data_by_filename('t/etc/data/basic.xls');
    is $mutable_ds->name, 'Dog Roster', '  ..and name is correct';

    is_deeply $mutable_ds->data, $xls_ds_data,
        'Data is as expected';
    is_deeply $mutable_ds->data_table, [["Name", "Age", "Gender"], @$xls_ds_data],
        'Data table is as expected';
    is $mutable_ds->as_raw, "Name\tAge\tGender\nVa Bene\t14\tfemale\nChloe\t2\tfemale\nGrover\t8\tmale\nChewie\t5\tmale\nGoochie\t1\tfemale\n", 'Got as Raw';

    ok my $excel = $mutable_ds->as_excel, 'can get excel object';
    open my $XLS, '<', \$excel;
    ok my $xls_data  = Spreadsheet::Read::ReadData($XLS, parser => 'xls'),
        'is a readable xls';
    close $XLS;
    is $xls_data->[1]{A1}, 'Name', 'Check header value';
    is $xls_data->[1]{C1}, 'Gender', 'Check header value';
    is $xls_data->[1]{A2}, 'Va Bene', 'Check data value';
    is $xls_data->[1]{A6}, 'Goochie', 'Check data value';
    is $xls_data->[1]{D3}, undef, 'Check for undef value';

    my @ds_cols = $mutable_ds->ds_columns_ordered->all;
    $ds_cols[0]->move_next();
    my @column_names = map {$_->name} $mutable_ds->ds_columns_ordered->all;
    is_deeply \@column_names, [qw(Age Name Gender)],
        'ds_columns_ordered gets columns in their proper order';

    # test dataset deletion
    my $schema_name = $mutable_ds->schema_name;
    my $table_name  = $mutable_ds->tablename;
    ok !exception { $mutable_ds->delete; }, 'can delete dataset okay';
    ok !$mutable_ds->_table_exists($table_name), '  ..datastore table is dropped';
    my $sth_table_exists = t::DB::get_schema->storage->dbh->table_info(undef, $schema_name, $table_name, 'TABLE');
    is_deeply $sth_table_exists->fetchall_arrayref, [], '  ...double checking, yep';

    # test page cloning
    t::DB::load_fixtures('clone_set');
    my $cloneable_page = $user->my_pages->search({title => {like => '%All Time'},})->first;
    my $new_ds         = $user->datasets_rs->find({name => 'IMDB Bottom 5'});
    my $cloned_page    = $new_ds->new_related('pages',{})
        ->clone_from_existing($cloneable_page);

    is $cloned_page->page_columns_ordered->first->template->to_jstmpl,
        $cloneable_page->page_columns_ordered->first->template->to_jstmpl,
            'Page and cloned page have identical columns';

    # dump_to_user()
    my $page_dump = $cloneable_page->dump_to_user();
    is_valid_json $page_dump, 'dump_to_user json is well formed';

    # clone_from_dump()
    my $dumpcloned_page = $new_ds->new_related('pages',{})
        ->clone_from_dump($page_dump);
    is $dumpcloned_page->page_columns_ordered->first->template->to_jstmpl,
        $cloneable_page->page_columns_ordered->first->template->to_jstmpl,
            'Page and cloned page have identical columns';
    is_json $page_dump, $dumpcloned_page->dump_to_user,
        'page and its dumpcloned page have equivalent json';
};

subtest 'Result::DatasetColumn' => sub {
    my $ds_column_rs = ResultSet('DatasetColumn');
    my $ds_column = $ds_column_rs->first;

    my $dataset = $ds_column->dataset;
    my $new_ds_col = $dataset->create_related('ds_columns', {
        name => 'Test Column', sort => 99,
        data_type_id => 1,
    });

    my $new_ds_col2 = $dataset->create_related('ds_columns', {
        name => 'Test Column 2', shortname => 'moo', sort => 99,
        data_type_id => 1,
    });
    is $new_ds_col2->shortname, 'moo',
        "auto shortname doesn't overwrite provided shortname";

    ok my $ds_col3 = $dataset->create_related('ds_columns', {
        name => q{}, sort => 98, data_type_id => 1,
    }), 'can create column w/ empty name';

    ok my $ds_col4 = $dataset->create_related('ds_columns', {
        name => q{#$*^(}, sort => 97, data_type_id => 1,
    }), 'can create column w/ non-ascii name';

    # mutating methods, create new dataset
    my $user = ResultSet('User')->first;
    my $mutable_ds = $user->import_data_by_filename('t/etc/data/basic.xls');


    # test data_type lookup column
    is $ds_col3->data_type(), 'text', 'can proxy to lookup';
    ok !exception { $ds_col3->data_type("numeric"); $ds_col3->update; },
        ' lookup_proxy lives w/ good lookup';
    is $ds_col3->data_type(), 'numeric', 'proxy to lookup produce correct value';
    is $ds_col4->data_type(), 'text', "similar column doesn\'t get same value";
    ok exception { $ds_col3->data_type("moo"); },
        ' lookup_proxy dies on bad lookup';

    # test accession_type lookup column
    $ds_col3->discard_changes; # needed b/c fk is nullable
    is $ds_col3->accession_type(), undef, 'accession_type not yet set';
    ok !exception {
        $ds_col3->accession_type('entrez_gene_id');
    }, 'Can successfully set accession type';
    $ds_col3->update;
    $ds_col3->discard_changes;
    is $ds_col3->accession_type(), 'entrez_gene_id', 'accession_type correctly set';


    # make sure we can import datasets w/ duplicate column names
    $user = ResultSet('User')->first;
    is_result my $dupe_cols_ds
        = $user->import_data_by_filename('t/etc/data/dupe_colnames.xls'),
            'Can successfully import dataset with duplicate column names';
    my @dupe_cols = $dupe_cols_ds->ds_columns_ordered->all;
    my %seen_colnames;
    my $dupes = grep {$seen_colnames{$_->shortname}++} @dupe_cols;
    ok !$dupes, q{  ...and columns names aren't repeated.};
};


subtest 'Result::Page' => sub {
    my $page = ResultSet('Page')->first;

    is $page->nbr_columns, 3, '::nbr_columns is correct';
    is $page->nbr_rows, 5,    '::nbr_rows is correct';

    my @page_cols = $page->page_columns_ordered->all;
    $page_cols[0]->move_next();
    my @column_names = map {$_->title} $page->page_columns_ordered->all;
    is_deeply \@column_names, [qw(Age Name Gender)],
        'page_columns_ordered gets columns in their proper order';


    my $movie_ds = ResultSet('Dataset')->find({name => 'IMDB Top 5',});
    my $movie_page = $movie_ds->create_related(
        'pages', {qw(title a preamble b postamble c)}
    );
    my $good_pcol = $movie_page->create_related(
        'page_columns', {title => 'Good Column', template => '[]', sort => 1,}
    );
    $good_pcol->update;
    ok !exception { $movie_page->templates_match_dataset },
        'empty templates match dataset';

    $good_pcol->template(Judoon::Tmpl->new_from_jstmpl('{{=title}}'));
    $good_pcol->update;
    ok !exception { $movie_page->templates_match_dataset },
        'valid templates match dataset';

    $good_pcol->template(Judoon::Tmpl->new_from_jstmpl('{{=nosuchname}}'));
    $good_pcol->update;
    isa_ok exception { $movie_page->templates_match_dataset },
        'Judoon::Error::InvalidTemplate',
            q{invalid templates don't match dataset};

};


subtest 'Result::PageColumn' => sub {
    my $page_column = ResultSet('PageColumn')->first;

    ok $page_column->template->to_jstmpl, 'can produce jquery';
    ok $page_column->template->get_nodes, 'can produce objects';

    ok $page_column->template(Judoon::Tmpl->new_from_jstmpl('<br>')),
        'can set template...';
    my @objects = $page_column->template->get_nodes;
    ok @objects == 1 && ref($objects[0]) eq 'Judoon::Tmpl::Node::Newline',
        '  ...and get correct objects back';
};

done_testing();
