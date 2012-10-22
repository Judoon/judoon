#/usr/bin/env perl

use strict;
use warnings;

use lib q{t/lib};

use Test::More;
use Test::Fatal;
use t::DB;

use Data::Printer;
use Judoon::Spreadsheet;
use Judoon::Tmpl::Factory ();
use Judoon::Tmpl::Translator;
use Spreadsheet::Read;

my $translator = Judoon::Tmpl::Translator->new;

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
    like exception { $user->import_data(); },
        qr{import_data\(\) needs a filehandle}i, 'import_data() dies w/o fh';

    open my $TEST_XLS, '<', 't/etc/data/basic.xls'
        or die "Can't open test spreadsheet: $!";
    is_result $user->import_data($TEST_XLS);
    close $TEST_XLS;

    # import_data_by_filename()
    is_result $user->import_data_by_filename('t/etc/data/basic.xls');

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


    # test importing from spreadsheets
    my $xls_ds_data = [
        ['Va Bene', 14, 'female'],
        ['Chloe',    2, 'female'],
        ['Grover',   8, 'male'  ],
        ['Chewie',   5, 'male'  ],
        ['Goochie',  1, 'female'],
    ];
    my $xls_cols = [
        {name => 'Name',   sort => 1, accession_type => q{}, url_root => q{},},
        {name => 'Age',    sort => 2, accession_type => q{}, url_root => q{},},
        {name => 'Gender', sort => 3, accession_type => q{}, url_root => q{},},
    ];

    # mutating methods, create new dataset
    my $user = ResultSet('User')->first;
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

    # test page cloning
    my $first_ds = $user->import_data_by_filename('t/etc/data/clone1.xls');
    my $first_page = $first_ds->add_to_pages({
        title     => "IMDB's Top 5 Movies of all time",
        preamble  => qq{Not gonna lie, these movies are pretty fucking amazing.},
        postamble => qq{If you haven't seen these, kill yourself.},
    });

    my @columns = (
        ['Name / Director', '<a href="{{=imdb}}">{{=title}}</a><br><strong>Directed By:</strong> {{=director}}'],
        ['Year',   '{{=year}}',],
        ['Rating', '{{=rating}}'],
    );

    my $i = 1;
    my @col_structs = map {
        my $rec = $_;
        my $tmpl = $translator->translate(
            from => 'JQueryTemplate', to => 'Native', template => $rec->[1],
        );
        {title => $rec->[0], sort => $i++, template => $tmpl,};
    } @columns;
    $first_page->add_to_page_columns($_) for (@col_structs);

    my $second_ds   = $user->import_data_by_filename('t/etc/data/clone2.xls');
    my $second_page = $second_ds->new_related('pages',{})
        ->clone_from_existing($first_page);
    $second_page->update({title => "IMDB's Bottom 5 Movies of all time"});

    is $second_page->page_columns_ordered->first->template,
        $first_page->page_columns_ordered->first->template,
            'Page and cloned page have identical columns';

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
    #is $new_ds_col->shortname, 'test_column', 'auto shortname works';
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
    #is $ds_col3->shortname, 'nothing', 'shortname defaulted correctly';
    is_deeply $ds_col3->linkset, [], 'unannotated column gives empty linkset';

    ok my $ds_col4 = $dataset->create_related('ds_columns', {
        name => q{#$*^(}, sort => 97, is_accession => 0, accession_type => q{},
        is_url => 1, url_root => q{http://google.com/?q=},
    }), 'can create column w/ non-ascii name';
    #is $ds_col4->shortname, '_____', 'shortname defaulted correctly';
    ok $ds_col4->linkset, 'can get linkset for url';

    # mutating methods, create new dataset
    my $user = ResultSet('User')->first;
    my $mutable_ds = $user->import_data_by_filename('t/etc/data/basic.xls');
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

    $good_pcol->set_template(
        $translator->to_objects(from => 'JQueryTemplate', template => '{{=title}}'),
    );
    $good_pcol->update;
    ok !exception { $movie_page->templates_match_dataset },
        'valid templates match dataset';

    $good_pcol->set_template(
        $translator->to_objects(from => 'JQueryTemplate', template => '{{=nosuchname}}'),
    );
    $good_pcol->update;
    isa_ok exception { $movie_page->templates_match_dataset },
        'Judoon::Error::InvalidTemplate',
            q{invalid templates don't match dataset};

};


subtest 'Result::PageColumn' => sub {
    my $page_column = ResultSet('PageColumn')->first;

    ok $page_column->template_to_jquery,     'can produce jquery';
    ok $page_column->template_to_objects,    'can produce objects';

    my $newline = Judoon::Tmpl::Factory::new_newline_node();
    ok $page_column->set_template($newline), 'can set template...';
    my @objects = $page_column->template_to_objects;
    ok @objects == 1 && ref($objects[0]) eq 'Judoon::Tmpl::Node::Newline',
        '  ...and get correct objects back';
};

done_testing();
