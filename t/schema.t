#!/usr/bin/env perl

use utf8;

use Data::Printer;
use DateTime;
use Judoon::Spreadsheet;
use Judoon::Table;
use Judoon::Tmpl;
use Judoon::Types::Core qw(CoreType_Text);
use Spreadsheet::ParseExcel;
use Test::Fatal;
use Test::JSON;

use Test::Roo;
use lib 't/lib';
with 't::Role::Schema';


sub ResultSet { return $_[0]->schema->resultset($_[1]); }
sub is_result { return isa_ok $_[0], 'DBIx::Class'; }


my $DATA_DIR = 't/etc/data';


after setup => sub {
    my ($self) = @_;
    $self->load_fixtures(qw(init basic));
};

test 'Result::User' => sub {
    my ($self) = @_;

    my $user_rs = $self->ResultSet('User');
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

test 'ResultSet::User' => sub {
    my ($self) = @_;

    my $user_rs = $self->ResultSet('User');

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

test 'Result::Dataset' => sub {
    my ($self) = @_;

    my $dataset = $self->ResultSet('Dataset')->first;
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
    my $user = $self->ResultSet('User')->find({username => 'testuser'});
    my $mutable_ds = $user->import_data_by_filename('t/etc/data/basic.xls');
    is $mutable_ds->name, 'Dog Roster', '  ..and name is correct';

    is_deeply $mutable_ds->data, $xls_ds_data,
        'Data is as expected';

    my $raw_data = Judoon::Table->new({
        data_source => $mutable_ds, header_type => 'long', format => 'tsv',
    })->table;
    is_deeply $raw_data, [["Name", "Age", "Gender"], @$xls_ds_data],
        'Data table is as expected';

    my $tsv_data = Judoon::Table->new({
        data_source => $mutable_ds, header_type => 'long', format => 'tsv',
    })->render;
    is $tsv_data, "Name\tAge\tGender\nVa Bene\t14\tfemale\nChloe\t2\tfemale\nGrover\t8\tmale\nChewie\t5\tmale\nGoochie\t1\tfemale\n", 'Got as Raw';
    is_deeply $mutable_ds->id_data, [map {[$_]} 1..5],
        'Id data is as expected';


    my $excel = Judoon::Table->new({
        data_source => $mutable_ds, header_type => 'long', format => 'xls',
    })->render;
    open my $XLS, '<', \$excel;
    my $generated_xls;
    ok !exception {
        $generated_xls = Spreadsheet::ParseExcel->new->parse($XLS);
    }, '  ...is a readable xls';
    close $XLS;

    my $gen_xls_data = $generated_xls->worksheet(0);
    is $gen_xls_data->get_cell(0,0)->value(), 'Name', 'Check header value';
    is $gen_xls_data->get_cell(0,2)->value(), 'Gender', 'Check header value';
    is $gen_xls_data->get_cell(1,0)->value(), 'Va Bene', 'Check data value';
    is $gen_xls_data->get_cell(5,0)->value(), 'Goochie', 'Check data value';
    is $gen_xls_data->get_cell(2,3), undef, 'Check for undef value';

    my @ds_cols = $mutable_ds->ds_columns_ordered->all;
    $ds_cols[0]->move_next();
    my @column_names = map {$_->name} $mutable_ds->ds_columns_ordered->all;
    is_deeply \@column_names, [qw(Age Name Gender)],
        'ds_columns_ordered gets columns in their proper order';

    # test dataset deletion
    my @pages      = $mutable_ds->pages_rs->all;
    my @linked_ids = (
        ['DatasetColumn', [map {$_->id} $mutable_ds->ds_columns_rs->all]],
        ['Page',          [map {$_->id} @pages]],
        ['PageColumn',    [map {$_->id} map {$_->page_columns_rs->all} @pages]],
    );
    my $schema_name = $mutable_ds->schema_name;
    my $table_name  = $mutable_ds->tablename;
    ok !exception { $mutable_ds->delete; }, 'can delete dataset okay';
    ok !$mutable_ds->_table_exists($table_name), '  ...datastore table is dropped';
    my $sth_table_exists = $self->schema->storage->dbh->table_info(undef, $schema_name, $table_name, 'TABLE');
    is_deeply $sth_table_exists->fetchall_arrayref, [], '  ...double checking, yep';
    for my $linked (@linked_ids) {
        my ($rs_name, $ids) = @$linked;
        is $self->ResultSet($rs_name)->search({id => {in => $ids}})->count,
            0, "  ...all linked ${rs_name}s gone.";
    }


    # test page cloning
    $self->load_fixtures('clone_set');
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


    # test non-unique column names
    my $repeat_ds = $user->import_data_by_filename("$DATA_DIR/repeat_cols.csv");
    my @repeat_dscols = $repeat_ds->ds_columns_ordered->all;
    is_deeply [map {$_->name} @repeat_dscols],
        ['repeat', map {"repeat ($_)"} 1..9],
            'duplicate names correctly assigned';
    is_deeply [map {$_->shortname} @repeat_dscols],
        ['repeat', map {"repeat_0$_"} 1..9],
            'duplicate shortnames correctly assigned';
    $repeat_ds->delete;

    # weird characters in column names
    for my $enc (qw(utf8 cp1252)) {
        my $encoded_ds = $user->import_data_by_filename("$DATA_DIR/encoding-${enc}.csv");
        my @encoded_dscols = $encoded_ds->ds_columns_ordered->all;
        is_deeply [map {$_->name} @encoded_dscols],
            ['ÜñîçøðÆ'], "${enc}-encoded names correctly decoded";
        is_deeply [map {$_->shortname} @encoded_dscols],
            ['unicodae'], "${enc}-encoded shortnames correctly filtered";
        $encoded_ds->delete;
    }

    # blank column titles
    my $blank_ds = $user->import_data_by_filename("$DATA_DIR/blank_header.csv");
    my @blank_dscols = $blank_ds->ds_columns_ordered->all;
    is_deeply [map {$_->name} @blank_dscols],
        ['First Column', '(untitled column)', 'Third Column',
         '(untitled column) (1)',],
             'blank names correctly assigned';
    is_deeply [map {$_->shortname} @blank_dscols],
        [q{first_column}, q{untitled}, q{third_column}, q{untitled_01},],
        'blank shortnames correctly assigned';
    $blank_ds->delete;

    # id column title reserved for use
    my $id_ds = $user->import_data_by_filename("$DATA_DIR/id_column.csv");
    my @id_cols = $id_ds->ds_columns_ordered->all;
    is_deeply [map {$_->shortname} @id_cols],
        [qw(id_01 id_02 id_03 _id)], 'reserved name "id" not used';
    is_deeply $id_ds->id_data, [[1],[2],[3]], 'id col has correct data';


    # table name beginning with numbers
    ok !exception {
        $user->import_data_by_filename("$DATA_DIR/numbername.xlsx");
    }, 'can import dataset whose name begins with numbers';


};

test 'Result::DatasetColumn' => sub {
    my ($self) = @_;

    my $ds_column_rs = $self->ResultSet('DatasetColumn');
    my $ds_column = $ds_column_rs->first;

    my $dataset = $ds_column->dataset;
    my $new_ds_col = $dataset->create_related('ds_columns', {
        name => 'Test Column', sort => 99,
        data_type => CoreType_Text,
    });

    my $new_ds_col2 = $dataset->create_related('ds_columns', {
        name => 'Test Column 2', shortname => 'moo', sort => 99,
        data_type => CoreType_Text,
    });
    is $new_ds_col2->shortname, 'moo',
        "auto shortname doesn't overwrite provided shortname";

    ok my $ds_col3 = $dataset->create_related('ds_columns', {
        name => q{}, sort => 98, data_type => CoreType_Text,
    }), 'can create column w/ empty name';

    ok my $ds_col4 = $dataset->create_related('ds_columns', {
        name => q{#$*^(}, sort => 97, data_type => CoreType_Text,
    }), 'can create column w/ non-ascii name';

    # mutating methods, create new dataset
    my $user = $self->ResultSet('User')->first;
    my $mutable_ds = $user->import_data_by_filename('t/etc/data/basic.xls');

    # make sure we can import datasets w/ duplicate column names
    $user = $self->ResultSet('User')->first;
    is_result my $dupe_cols_ds
        = $user->import_data_by_filename('t/etc/data/dupe_colnames.xls'),
            'Can successfully import dataset with duplicate column names';
    my @dupe_cols = $dupe_cols_ds->ds_columns_ordered->all;
    my %seen_colnames;
    my $dupes = grep {$seen_colnames{$_->shortname}++} @dupe_cols;
    ok !$dupes, q{  ...and columns names aren't repeated.};
};


test 'Result::Page' => sub {
    my ($self) = @_;

    my $page = $self->ResultSet('Page')->first;

    is $page->nbr_columns, 3, '::nbr_columns is correct';
    is $page->nbr_rows, 5,    '::nbr_rows is correct';

    my @page_cols = $page->page_columns_ordered->all;
    $page_cols[0]->move_next();
    my @column_names = map {$_->title} $page->page_columns_ordered->all;
    is_deeply \@column_names, [qw(Age Name Gender)],
        'page_columns_ordered gets columns in their proper order';


    my $movie_ds = $self->ResultSet('Dataset')->find({name => 'IMDB Top 5',});
    my $movie_page = $movie_ds->create_related(
        'pages', {qw(title a preamble b postamble c)}
    );
    my $good_pcol = $movie_page->create_related(
        'page_columns', {title => 'Good Column', template => '[]', sort => 1,}
    );
    $good_pcol->update;
    ok !exception { $movie_page->templates_match_dataset },
        'empty templates match dataset';

    $good_pcol->template(Judoon::Tmpl->new_from_jstmpl('{{title}}'));
    $good_pcol->update;
    ok !exception { $movie_page->templates_match_dataset },
        'valid templates match dataset';

    $good_pcol->template(Judoon::Tmpl->new_from_jstmpl('{{nosuchname}}'));
    $good_pcol->update;
    isa_ok exception { $movie_page->templates_match_dataset },
        'Judoon::Error::Template',
            q{invalid templates don't match dataset};

};


test 'Result::PageColumn' => sub {
    my ($self) = @_;

    my $page_column = $self->ResultSet('PageColumn')->first;

    ok $page_column->template->to_jstmpl, 'can produce jquery';
    ok $page_column->template->get_nodes, 'can produce objects';

    ok $page_column->template(Judoon::Tmpl->new_from_jstmpl('<br>')),
        'can set template...';
    my @objects = $page_column->template->get_nodes;
    ok @objects == 1 && ref($objects[0]) eq 'Judoon::Tmpl::Node::Newline',
        '  ...and get correct objects back';
};


test 'Result(Set)?::Token' => sub {
    my ($self) = @_;

    my $token_rs = $self->ResultSet('Token');
    my $user  = $self->ResultSet('User')->first;

    my $token = $token_rs->new_result({user => $user});
    $token->password_reset();
    $token->insert;

    ok my $token_value = $token->value, 'token has a default value';
    ok my $expiry = $token->expires, 'token has default expiry';

    my $now  = DateTime->now;
    my $soon = DateTime->now->add(hours => 24);
    ok( (($expiry >= $now) && ($expiry <= $soon)), 'expiry is within 24 hours');
    is $token->password_reset, 'password_reset', 'correctly set action';

    my $dupe_token = $token_rs->new_result({
        user => $user, value => $token_value, action => 'password_reset',
    });
    like exception { $dupe_token->insert }, qr{violates unique constraint},
        'token insert fails with duplicate value';

    my $found_token = $token_rs->find_by_value($token_value);
    ok $found_token, 'able to find exisitng token by its value';
    is $user->related_resultset('tokens')->password_reset->count, 1,
        'found tokens by RS::password_reset';
    is $user->related_resultset('tokens')->unexpired->count, 1,
        'found tokens by RS::unexpired';

    my $second_token = $user->new_reset_token();
    is_result($second_token);
    my @all_tokens = $user->valid_reset_tokens;
    is @all_tokens, 2, 'found both valid reset tokens';

    $all_tokens[0]->expires(DateTime->now->subtract(hours => 100));
    $all_tokens[0]->update;
    $all_tokens[1]->action('something else');
    $all_tokens[1]->update;
    is $user->valid_reset_tokens, 0, 'no more valid reset tokens';
    is $user->search_related('tokens')->password_reset->count, 1,
        'one password_reset token';
    is $user->search_related('tokens')->unexpired->count, 1,
        'one unexpired token';

    ok $all_tokens[0]->is_expired(), 'is_expired() works';

};

run_me();
done_testing();
