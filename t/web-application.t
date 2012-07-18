#/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::DBIx::Class {
    schema_class => 'Judoon::DB::User::Schema',
    connect_info => ['dbi:SQLite:dbname=t/var/testdb.sqlite','',''],
};
use Test::WWW::Mechanize::Catalyst;

use Config::General;
use Data::Printer;
use File::Temp qw(tempdir);
use FindBin qw($Bin);


# set up catalyst test config
my $TEST_CONF_FILE = "$Bin/../judoon_web_test.conf";
die "test conf already exists: $TEST_CONF_FILE" if (-e $TEST_CONF_FILE);
$ENV{'JUDOON_WEB_CONFIG_LOCAL_SUFFIX'} = 'test';
my $test_config = Config::General->new({
    'Model::User' => {
         connect_info => Schema()->storage->connect_info->[0],
    },
    'Plugin::Session' => {
        storage => tempdir(CLEANUP => 1),
    },
});
$test_config->save_file($TEST_CONF_FILE);


# install basic fixtures
my %users = (
    testuser => {
        username => 'testuser', password => 'testuser',
        name => 'Test User', email_address => 'testuser@example.com',
    },
);
fixtures_ok( sub {
    my ($schema) = @_;
    $schema->resultset('User')->create_user($users{testuser});
} );


# start test server
my $mech = Test::WWW::Mechanize::Catalyst->new(
    catalyst_app => 'Judoon::Web',
);
ok $mech, 'created test mech' or BAIL_OUT;


# START TESTING!!!!

subtest 'Basic Tests' => sub {
    $mech->get_ok('/', 'get frontpage');
    $mech->get_ok('/placeholder', 'get placeholder page');
    $mech->get_ok('/api');

    subtest 'Login / Logout' => sub {
        redirects_to_ok('/settings/profile', '/login');

        $mech->get_ok('/login', 'get login page');
        $mech->submit_form_ok({
            form_number => 1,
            fields => {username => 'testuser', password => 'testuser',},
        }, 'submitted login okay');

        no_redirect_ok('/settings/profile', 'can get to profile after login');
        $mech->get_ok('/logout', 'can logout okay');
        redirects_to_ok('/settings/profile', '/login');
    };

};


subtest 'User Tests' => sub {
    my %newuser = (
        'user.username' => 'newuser', 'user.password' => 'newuserisme',
        'user.email_address' => 'newuser@example.com',
        'user.name' => 'New User',
    );

    subtest 'Signup' => sub {
        $mech->get_ok('/signup', 'got signup page');

        $newuser{'user.confirm_password'} = 'wontmatch';
        $mech->post_ok('/signup', \%newuser);
        $mech->content_like(
            qr{passwords do not match}i,
            q{can't create user w/o matching passwords},
        );

        $newuser{'user.confirm_password'} = 'newuserisme';
        $newuser{'user.username'}         = 'testuser';
        $mech->post_ok('/signup', \%newuser);
        $mech->content_like(
            qr{this username is already taken}i,
            q{can't create user w/ same name as current user},
        );


        $newuser{'user.username'} = 'newuser';
        $mech->post_ok('/signup', \%newuser, 'can create new user');
        like $mech->uri, qr{/user/newuser},
            '  ...and send new user to their datasets';
    };

    subtest 'Profile' => sub {
        redirects_to_ok('/settings','/settings/profile');

        $mech->get_ok('/settings/profile', 'get user profile');
        $mech->post_ok(
            '/settings/profile',
            {
                'user.email_address' => 'newuser@example.com',
                'user.name'          => 'New Name',
                'user.phone_number'  => '555-5505',
            },
            'can update profile',
        );
        my ($phone_input) = $mech->grep_inputs({name => qr/^user\.phone_number$/});
        is $phone_input->value, '555-5505', 'phone number has been updated';

        # broken: we're way too permissive right now
        # $mech->post_ok(
        #     '/settings/profile',
        #     {
        #         'user.email_address' => undef,
        #         'user.name'          => 'New Name',
        #         'user.phone_number'  => '555-5505',
        #     },
        # );
        # $mech->content_like(qr{unable to update profile}i, q{cant duplicate email address});
    };

    subtest 'Password' => sub {
        $mech->get_ok('/settings/password', 'get user password change');

        $mech->post_ok(
            '/settings/password',
            {old_password => $newuser{'user.password'},},
        );
        $mech->content_like(qr/Something is missing/i, 'need all three fields');

        $mech->post_ok(
            '/settings/password',
            {old_password => 'incorrect', new_password => 'boobooboo', confirm_new_password => 'boobooboo',},
        );
        $mech->content_like(qr/old password is incorrect/i, 'cant update password without old password');

        $mech->post_ok(
            '/settings/password',
            {old_password => $newuser{'user.password'}, new_password => 'boo', confirm_new_password => 'boo',},
        );
        $mech->content_like(qr/Invalid password/i, 'cant update password with invalid password');

        $mech->post_ok(
            '/settings/password',
            {
                old_password         => $newuser{'user.password'},
                new_password         => 'newuserisstillme',
                confirm_new_password => 'newuserisstillme',
            },
            'able to update password',
        );
        $mech->content_like(qr/Your password has been updated/, 'can update password');
        $newuser{'user.password'} = 'newuserisstillme';
    };


    subtest 'User Overview' => sub {
        $mech->get('/logout');
        $mech->get_ok('/user/newuser', 'can get others overview w/o login');
        $mech->content_like(qr/newuser's overview/i,
            'got welcome message for visitor w/o login');

        login('testuser');
        $mech->get_ok('/user/testuser', 'can get own overview');
        $mech->content_like(qr/Welcome, $users{testuser}{name}/i,
            'welcome message for owner');

        $mech->get_ok('/user/newuser', 'can get others overview w/ login');
        $mech->content_like(qr/newuser's overview/i,
            'got welcome message for visitor w/ login');

        $mech->get('/user/baduser');
        is $mech->status, 404, 'baduser 404s';
    };

};


subtest 'Dataset' => sub {
    login('testuser');

    # GET dataset/list
    redirects_to_ok('/user/testuser/dataset','/user/testuser');

    # POST dataset/list
    $mech->submit_form_ok({
        form_name => 'add_dataset',
        fields => {
            dataset => ["t/etc/data/test1.xls"],
        },
    }, 'Can upload a dataset', );

    # GET dataset/object
    my @ds_links = $mech->find_all_links(
        url_regex => qr{/user/testuser/dataset/\d+$}
    );
    ok @ds_links, 'found links to specific datasets';
    $mech->get_ok($ds_links[0], 'can get dataset page');

    # PUT dataset/object
    my %ds_update = (
        'dataset.name'  => 'Brand New Name',
        'dataset.notes' => 'These are some notes',
    );
    $mech->post_ok(
        $mech->uri,
        { %ds_update, 'x-tunneled-method' => 'PUT', },
        'can update dataset',
    );
    while (my ($k, $v) = each %ds_update) {
        my ($ds_input) = $mech->grep_inputs({name => qr/^$k$/});
        is $ds_input->value, $v, "$k has been updated";
    }


    # DELETE dataset/object
    $mech->get('/user/testuser');
    $mech->submit_form_ok({
        form_name => 'delete_dataset_1',
    }, 'delete the dataset');
    like $mech->uri, qr{/user/testuser}, 'back to user overview';
    $mech->content_unlike(qr{table[^\v]dataset_list}, 'no more datasets on this page');
};


subtest 'DatasetColumns' => sub {
    login('testuser');

    # create dataset
    $mech->get('/user/testuser');
    $mech->submit_form_ok({
        form_name => 'add_dataset',
        fields => {
            dataset => ["t/etc/data/test1.xls"],
        },
    }, 'Can upload a dataset', );

    # GET datasetcolumn/list
    my @ds_col_list_links = $mech->find_all_links(
        url_regex => qr{/user/testuser/dataset/\d+/column$}
    );
    ok @ds_col_list_links, 'found links to dataset column lists';
    $mech->get_ok($ds_col_list_links[0], 'can get dataset column list page');

    # PUT datasetcolumn/list
    # todo: add delete column test

    # GET datasetcolumn/object
    my @ds_col_links = $mech->find_all_links(
        url_regex => qr{/user/testuser/dataset/\d+/column/\d+$}
    );
    ok @ds_col_links, 'found links to specific dataset columns';
    $mech->get_ok($ds_col_links[0], 'can get dataset column page');

    # PUT datatsetcolumn/object
    my %ds_col_update = (
        'column.is_url'   => '1',
        'column.url_root' => 'http://www.google.com/',
    );
    $mech->post_ok(
        $mech->uri,
        { %ds_col_update, 'x-tunneled-method' => 'PUT', },
        'can update dataset column',
    );
    $mech->content_like(qr{url: http://www.google.com/},
                        'can update dataset column');
};


subtest 'Page' => sub {
    login('testuser');
    $mech->get('/user/testuser');

    # POST page/list
    $mech->submit_form_ok({
        form_name => 'add_page_1',
    }, 'add new page');
    my $page_uri = $mech->uri;
    like $page_uri, qr{/user/testuser/dataset/\d+/page/\d+},
        q{got new page's edit page};

    # GET page/object
    $mech->get('/user/testuser');
    $mech->get_ok($page_uri);

    # GET page/object preview page
    $mech->get_ok("$page_uri?view=preview");

    # PUT page/object
    $mech->get($page_uri);
    my %page_update = (
        'page.title'     => 'This is a new page',
        'page.preamble'  => 'Mumble, mumble, preamble',
        'page.postamble' => 'Humble bumblebee postamble',
    );
    $mech->post_ok(
        $mech->uri,
        { %page_update, 'x-tunneled-method' => 'PUT', },
        'can update page',
    );
    while (my ($k, $v) = each %page_update) {
        my ($page_input) = $mech->grep_inputs({name => qr/^$k$/});
        is $page_input->value, $v, "$k has been updated";
    }

    # DELETE page/object
    $mech->get('/user/testuser');
    $mech->submit_form_ok({
        form_name => 'delete_page_1',
    }, 'delete the page');
    like $mech->uri, qr{/user/testuser}, 'back to user overview';
    $mech->content_unlike(qr{table[^\v]page_list}, 'no more pages on the overview');
};


subtest 'PageColumn' => sub {
    login('testuser');
    $mech->get('/user/testuser');

    my ($page_link) = $mech->find_all_links(
        url_regex => qr{/user/testuser/dataset/\d+/page/\d+$}
    );
    $mech->get($page_link);

    # POST pagecolumn/list
    $mech->submit_form_ok({
        form_name => 'add_page_column_form',
        fields => { 'page_column.title' => 'Chaang Column', },
    }, 'can create new page column',);
    my $pagecol_link = $mech->uri;
    like $pagecol_link, qr{/user/testuser/dataset/\d+/page/\d+/column/\d+},
        'was sent to column page';

    # PUT pagecolumn/object
    $mech->submit_form_ok({
        form_name => 'pagecol_form',
        fields => {
            'page_column.title' => 'Chaang Column Update',
        },
    }, 'can update page column (simple)',);
    like $mech->uri, qr{/user/testuser/dataset/\d+/page/\d+},
        'was sent back to page edit page';
    $mech->get($pagecol_link);
    my ($pagecol_title) = $mech->grep_inputs({name => qr/^page_column.title$/});
    is $pagecol_title->value, 'Chaang Column Update', 'field was updated';

    # GET pagecolumn/object
    $mech->get($page_link);
    $mech->follow_link_ok({
        url_regex => qr{/page/\d+/column/\d+},
    }, 'can get all pagecolumn links');

    # DELETE pagecolumn/object

};


# These tests are a bit gratuitious and don't really fit anywhere
# else.  It's mostly about trying to achieve 100% test coverage.
subtest 'Complete Coverage' => sub {
    login('testuser');
    $mech->get('/user/testuser');

    # test for error handling of ::Controller::Role::ExtractParams
    my ($ds_link) = $mech->find_all_links(
        url_regex => qr{/user/testuser/dataset/\d+/?$}
    );
    $mech->get($ds_link);
    $mech->post_ok(
        $mech->uri,
        { 'dataset.name' => 'boo', 'x-tunneled-method' => 'PUT', 'dataset.notes' => undef, },
        'can update dataset w/ undef param',
    );
    my ($ds_input) = $mech->grep_inputs({name => qr/^dataset\.notes$/});
    is $ds_input->value, q{}, "ExtractParams sets undef parameter to q{}";
};


unlink $TEST_CONF_FILE if (-e $TEST_CONF_FILE);
done_testing();


sub login {
    my ($user) = @_;
    $mech->get('/login');
    $mech->submit_form(
        form_number => 1,
        fields => {
            username => $users{$user}->{username},
            password => $users{$user}->{password},
        },
    );
}

sub redirects_ok {
    my ($req_url) = @_;

    my $req_redir = $mech->requests_redirectable();
    $mech->requests_redirectable([]);
    $mech->get($req_url);
    is($mech->status(), 302, 'requests for ' . $req_url . ' are redirected');
    $mech->requests_redirectable($req_redir);
}

sub redirects_to_ok {
    my ($req_url, $res_url) = @_;
    redirects_ok($req_url);
    $mech->get_ok($req_url, 'Redirection for ' . $req_url . ' succeeded...');
    like($mech->uri(), qr/$res_url/, '  ...to correct url: ' . $res_url);
}

sub no_redirect_ok {
    my ($req_url, $descr) = @_;
    $descr //= 'requests for ' . $req_url . ' are not redirected';

    my $req_redir = $mech->requests_redirectable();
    $mech->requests_redirectable([]);
    $mech->get($req_url);
    is $mech->status(), 200, $descr;
    $mech->requests_redirectable($req_redir);
}
