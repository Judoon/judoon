#!/usr/bin/env perl

use strict;
use warnings;

use lib q{t/lib};

BEGIN {
    $ENV{EMAIL_SENDER_TRANSPORT} = 'Test';
}


use Test::More;
use t::DB;

use Config::General;
use Data::Printer;
use Email::Sender::Simple;
use File::Temp qw(tempdir);
use FindBin qw($Bin);
use HTML::Selector::XPath::Simple;
use List::AllUtils ();


# install basic fixtures
my %users = (
    testuser => t::DB::get_testuser(),
    newuser => {
        username => 'newuser', password => 'newuserisme',
        name => 'New User', email_address => 'newuser@example.com',
    },
);

my $DATA_DIR = 't/etc/data';
my %spreadsheets = (
    basic       => "$DATA_DIR/basic.xls",
    troublesome => "$DATA_DIR/troublesome.xls",
    clone1      => "$DATA_DIR/clone1.xls",
    clone2      => "$DATA_DIR/clone2.xls",
);

my %alert_classes = (
    error  => 'alert-error', notice => 'alert-info',
    success => 'alert-success', warning => 'alert-block',
);


# start test server
my $mech = t::DB::new_mech();
ok $mech, 'created test mech' or BAIL_OUT;


# START TESTING!!!!

subtest 'Basic Tests' => sub {
    $mech->get_ok('/', 'get frontpage');
    $mech->get_ok('/placeholder', 'get placeholder page');
    $mech->get_ok('/api');
    $mech->get_ok('/get_started');
};


subtest 'Login / Logout' => sub {
    redirects_to_ok('/settings/profile', '/login');

    my %credentials = (
        username => $users{testuser}->{username},
        password => $users{testuser}->{password},
    ),
    $mech->get_ok('/login', 'get login page');

    # bad login
    $mech->submit_form_ok({
        form_name => 'login_form',
        fields    => {%credentials, password => 'badpass'},
    }, "can submit login form with bad data without error");
    user_error_like(qr{Username or password is incorrect}i);
    redirects_to_ok('/settings/profile', '/login');

    # good login
    $mech->submit_form_ok({
        form_name => 'login_form',
        fields => \%credentials,
    }, 'submitted login okay');
    no_redirect_ok('/settings/profile', 'can get to profile after login');

    # can't re-login
    redirects_to_ok('/login', '/user/testuser');
    $mech->post('/login', \%credentials,);
    like $mech->uri, qr{/user/testuser$},
        'posting to login redirects to overview';

    $mech->get_ok('/get_started', 'get get_started page while logged-in');

    # logout
    $mech->get_ok('/logout', 'can logout okay');
    redirects_to_ok('/settings/profile', '/login');
};


subtest 'Account' => sub {

    subtest 'Account List' => sub {
        logout();
        redirects_to_ok('/account', '/login');
        login('testuser');
        redirects_to_ok('/account', '/user/testuser');
    };


    my $newuser_canon = $users{newuser};
    my %newuser = map {; "user.$_" => $newuser_canon->{$_}}
        keys %$newuser_canon;

    subtest 'Signup' => sub {
        $mech->get_ok('/account/signup', 'got signup page');

        $newuser{'user.confirm_password'} = 'wontmatch';
        $mech->post_ok('/account/signup', \%newuser);
        $mech->content_like(
            qr{passwords do not match}i,
            q{can't create user w/o matching passwords},
        );

        $newuser{'user.confirm_password'} = $newuser{'user.password'};
        $newuser{'user.username'}         = 'testuser';
        $mech->post_ok('/account/signup', \%newuser);
        $mech->content_like(
            qr{this username is already taken}i,
            q{can't create user w/ same name as current user},
        );


        $newuser{'user.username'} = 'newuser';
        $mech->post_ok('/account/signup', \%newuser, 'can create new user');
        like $mech->uri, qr{/user/newuser},
            '  ...and send new user to their datasets';
    };

    subtest 'Settings' => sub {
        $mech->get_ok('/settings', 'Got settings page');
        $mech->links_ok(
            [$mech->find_all_links(url_regex => qr{/settings/})],
            'links are good',
        );
    };

    subtest 'Profile' => sub {
        $mech->get_ok('/settings/profile', 'get user profile');
        $mech->post_ok(
            '/settings/profile',
            {
                'user.email_address' => 'newuser@example.com',
                'user.name'          => 'New Name',
            },
            'can update profile',
        );
        $mech->form_name('profile_form');
        my ($name_input) = $mech->grep_inputs({name => qr/^user\.name$/});
        is $name_input->value, 'New Name', 'phone number has been updated';

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

        $mech->submit_form_ok({
            form_name => 'password_form',
            fields    => {old_password => $newuser{'user.password'},},
        }, 'submit_ok: need all three fields');
        user_error_like(qr/New password must not be blank/i);

        $mech->submit_form_ok({
            form_name => 'password_form',
            fields    => {
                old_password => 'incorrect', new_password => 'boobooboo',
                confirm_new_password => 'boobooboo',
            },
        }, q{submit_ok: can't change password when old password is wrong},);
        user_error_like(qr/old password is incorrect/i);

        $mech->submit_form_ok({
            form_name => 'password_form',
            fields    => {
                old_password => $newuser{'user.password'},
                new_password => 'boo',
                confirm_new_password => 'boo',
            },
        }, 'submit_ok: cant update password with invalid password',);
        user_error_like(qr/Invalid password/i);

        $mech->submit_form_ok({
            form_name => 'password_form',
            fields    => {
                old_password         => $newuser{'user.password'},
                new_password         => 'newuserisstillme',
                confirm_new_password => 'newuserisstillme',
            },
        }, 'submit_ok: able to update password');
        user_success_like(qr/Your password has been updated/);

        $newuser_canon->{password} = 'newuserisstillme';
    };

};


subtest 'Password Reset' => sub {
    logout();

    my $pass_resend_uri = '/account/password_reset';
    $mech->get_ok($pass_resend_uri, 'get password resend page ok');

    subtest 'Request Failures' => sub {
        my @errors = (
            [q{no password reset w/ bad email},    {email_address => 'nope@nope.com'},],
            [q{no password reset w/ bad username}, {username => 'doesnt_exist'},],
            [q{no password reset w/o args},        {},],
        );
        for my $error (@errors) {
            my ($msg, $args,) = @$error;
            $mech->submit_form_ok({
                form_name => 'resend_password_form', fields => $args,
            }, "submit_ok: $msg");
            user_error_like(qr{Couldn't find an account});
        }
    };

    my $bad_reset_uri;
    subtest 'Request Successes' => sub {
        my @wins = (
            ['can request password reset by email', {email_address => $users{testuser}->{email_address}},],
            ['can request password reset by username', {username => 'testuser'},],
        );

        for my $win (@wins) {
            my ($msg, $args) = @$win;
            $mech->get($pass_resend_uri);
            $mech->submit_form_ok({
                form_name => 'resend_password_form', fields => $args,
            }, "submit_ok: $msg");
            user_notice_like(qr{email has been sent});
            like $mech->uri, qr{/login$}, '..then sent to login page';

            my ($reset_email) = get_emails();
            my $body = $reset_email->{email}->as_string;
            like $body, qr{judoon password reset}i, 'password reset email sent';
            my ($reset_uri) = ($body =~ m{http://[^/]+(/\S+)});
            $bad_reset_uri  ||= $reset_uri . 'totally_bogus';

            # make sure we can log in as normal user even after passwd reset
            login('testuser');
            redirects_to_ok($pass_resend_uri, '/user/testuser',);
            logout();

            $mech->get_ok($reset_uri, 'can get uri reset page');
            like $mech->content(), qr{Confirm New Password},
                '  ...make sure we have correct page';
            unlike $mech->content(), qr{Old Password},
                '  ...dont ask for old password';

            $mech->submit_form_ok({
                form_name => 'password_form',
                fields    => {
                    new_password         => 'this',
                    confirm_new_password => 'that',
                },
            }, "submit_ok: can't change password when new passwords don't match");
            user_error_like(qr/passwords do not match/i);

            $mech->submit_form_ok({
                form_name => 'password_form',
                fields    => {
                    new_password         => '',
                    confirm_new_password => '',
                },
            }, q{can't change password when one of new passwords is blank},);
            user_error_like(qr/password must not be blank/i);

            $mech->submit_form_ok({
                form_name => 'password_form',
                fields    => {
                    new_password         => 'this',
                    confirm_new_password => 'this',
                },
            }, q{can't change password when passwords are invalid},);
            user_error_like(qr/invalid password/i);

            $mech->submit_form_ok({
                form_name => 'password_form',
                fields => {qw(new_password newpasswd confirm_new_password newpasswd)},
            }, 'submit password reset okay');
            like $mech->uri, qr{/user/testuser$}, 'sent to testuser overview page';

            logout();
            $users{testuser}->{password} = 'newpasswd';
            login('testuser');
            like $mech->uri, qr{/user/testuser}, 'Password successfully reset';
            logout();

            $mech->get($reset_uri);
            like $mech->uri, qr{/login},
                'reset token deleted after successful password reset';
            user_error_like(qr{No action found for token});
        }
    };

    subtest 'Reset Failures' => sub {
        $mech->get($bad_reset_uri);
        like $mech->uri(), qr{/login$},
            'bad login token sends you to the login page';
        user_error_like(qr{No action found for token});

        # forcibly expire token and test app response
        $mech->get($pass_resend_uri);
        $mech->submit_form(
            form_name => 'resend_password_form',
            fields    => {username => 'testuser'},
        );
        my ($expired_reset_email) = get_emails();
        my $expired_reset_body = $expired_reset_email->{email}->as_string;
        my ($expired_reset_uri) = ($expired_reset_body =~ m{http://[^/]+(/\S+)});
        my ($expired_reset_token) = ($expired_reset_uri =~ m/value=(\S+)/);

        my $expired_token = t::DB::ResultSet('Token')->find({value => $expired_reset_token});
        $expired_token->expires( DateTime->new(year => 2000, day => 1, month => 1) );
        $expired_token->update;

        $mech->get($expired_reset_uri);
        like $mech->uri, qr{/account/password_reset},
            'expired reset tokens sends us back to login';
        user_error_like(qr/your password reset token has expired/i);
    };

    # needed tests:
    #   sending email fails: resend_password_POST
    #     not sure how to do this, look at Email::Sender::Transport::Failable
};


subtest 'User List' => sub {
    logout();
    redirects_to_ok('/user', '/login');
    login('testuser');
    redirects_to_ok('/user', '/user/testuser');
};


subtest 'User Overview' => sub {
    logout();
    $mech->get_ok('/user/newuser', 'can get others overview w/o login');
    $mech->content_like(qr/newuser/i,
        'got welcome message for visitor w/o login');

    login('testuser');
    $mech->get_ok('/user/testuser', 'can get own overview');
    $mech->content_like(qr/id="dataset_upload_help"/i,
        'can find upload dataset widget');

    $mech->get_ok('/user/newuser', 'can get others overview w/ login');
    $mech->content_like(qr/newuser/i,
        'got welcome message for visitor w/ login');

    $mech->get('/user/baduser');
    is $mech->status, 404, 'baduser 404s';
};


subtest 'Dataset' => sub {
    login('testuser');

    my $dataset_list_uri = '/user/testuser/dataset';

    # GET dataset/list
    redirects_to_ok($dataset_list_uri, '/user/testuser');

    # POST dataset/list
    $mech->get('/user/testuser');
    my $dataset_uri = add_new_object_ok({
        object => 'dataset', list_uri => '/user/testuser',
        form_name => 'add_dataset', form_args => {
            'dataset.file' => [$spreadsheets{basic}],
        }, page_uri_re => qr{/user/testuser/dataset/\d+},
    });

    # fixme: PUT dataset/list
    # $mech->put($dataset_list_uri);
    # is $mech->status(), 405, 'no PUT to dataset/list';
    # $mech->post($dataset_list_uri, {'x-tunneled-method' => 'PUT'});
    # is $mech->status(), 405, 'no tunneled PUT to dataset/list';

    # DELETE dataset/list
    $mech->delete($dataset_list_uri, {},);
    is $mech->status(), 405, 'no DELETE to dataset/list';
    $mech->post($dataset_list_uri, {'x-tunneled-method' => 'DELETE'});
    is $mech->status(), 405, 'no tunneled DELETE to dataset/list';

    # GET dataset/object
    $mech->get_ok($dataset_uri, 'can get dataset page');

    # POST dataset/object
    $mech->post($dataset_uri, {},);
    is $mech->status(), 405, 'no POST to dataset/object';

    # PUT dataset/object
    puts_ok('dataset', $dataset_uri, 'dataset_edit', {
        'dataset.name'       => 'Brand New Name',
        'dataset.notes'      => 'These are some notes',
        'dataset.permission' => 'public',
    });

    # DELETE dataset/object
    my ($dataset_id) = ($dataset_uri =~ m{(\d+)$});
    delete_ok({
        object => 'dataset', object_id => $dataset_id,
        object_uri => $dataset_uri, list_uri => '/user/testuser',
        form_prefix => 'delete_dataset_',
    });

    # GET dataset/bad_object
    $mech->get('/user/testuser/dataset/999999999');
    is $mech->status, 404, "don't die on nonexistent page (valid id type)";
    $mech->get('/user/testuser/dataset/moo');
    is $mech->status, 404, "don't die on nonexistent page (invalid id type)";
};


subtest 'DatasetColumns' => sub {
    login('testuser');

    # create dataset
    $mech->get('/user/testuser');
    $mech->submit_form_ok({
        form_name => 'add_dataset',
        fields => {
            'dataset.file' => [$spreadsheets{basic}],
        },
    }, 'Can upload a dataset', );


    # GET datasetcolumn/list
    my $dscol_list_uri = get_link_like_ok("dataset column list",
         qr{/user/testuser/dataset/\d+/column$});

    # fixme: POST   datasetcolumn/list
    # fixme: PUT    datasetcolumn/list

    # DELETE datasetcolumn/list
    $mech->delete($dscol_list_uri, {},);
    is $mech->status(), 405, 'no DELETE to dataset_column/list';
    $mech->post($dscol_list_uri, {'x-tunneled-method' => 'DELETE'});
    is $mech->status(), 405, 'no tunneled DELETE to dataset_column/list';

    # GET datasetcolumn/object
    $mech->get($dscol_list_uri);
    my $dscol_uri = get_link_like_ok("dataset column",
         qr{/user/testuser/dataset/\d+/column/\d+$});

    # POST   datasetcolumn/object
    $mech->post($dscol_uri, {},);
    is $mech->status(), 405, 'no POST to dataset_column/object';

    # fixme: PUT    datasetcolumn/object
    # fixme: DELETE datasetcolumn/object

    # GET datasetcolumn/bad_object
    $mech->get($dscol_uri . '99999999');
    is $mech->status, 404, "don't die on nonexistent page (valid id type)";
    $mech->get($dscol_uri . 'moo');
    is $mech->status, 404, "don't die on nonexistent page (invalid id type)";

    # DISABLED UNTIL dscolumn edit page rework
    # PUT datatsetcolumn/object
    # puts_ok('dataset_column', $dscol_uri, {});
    # $mech->get($dscol_list_uri);
    # $mech->content_like(qr{url: http://www.google.com/},
    #                     'can update dataset column');
};


subtest 'Page' => sub {
    login('testuser');

    # fixme: PUT    page/list

    # POST page/list
    my $page_uri = add_new_object_ok({
        object => 'page', list_uri => '/user/testuser',
        form_name => 'add_page_1', form_args => {},
        page_uri_re => qr{/user/testuser/dataset/\d+/page/\d+},
    });

    (my $page_list_uri = $page_uri) =~ s{/\d+$}{};

    # GET page/list
    redirects_to_ok($page_list_uri, '/user/testuser');

    # DELETE page/list
    $mech->delete($page_list_uri, {},);
    is $mech->status(), 405, 'no DELETE to page/list';
    $mech->post($page_list_uri, {'x-tunneled-method' => 'DELETE'});
    is $mech->status(), 405, 'no tunneled DELETE to page/list';

    # GET page/object
    $mech->get_ok($page_uri, 'get page edit page');

    # GET page/object preview page
    $mech->get_ok("$page_uri?view=preview", 'get page preview page');

    # PUT page/object
    puts_ok("page", $page_uri, 'page_edit', {
        'page.title'     => 'This is a new page',
        'page.preamble'  => 'Mumble, mumble, preamble',
        'page.postamble' => 'Humble bumblebee postamble',
    });

    # POST page/object
    $mech->post($page_uri, {},);
    is $mech->status(), 405, 'no POST to page/object';

    # DELETE page/object
    my ($page_id) = ($page_uri =~ m{(\d+)$});
    delete_ok({
        object => 'page', object_id => $page_id,
        object_uri => $page_uri, list_uri => '/user/testuser',
        form_prefix => 'delete_page_',
    });

    # GET page/bad_object
    $mech->get($page_uri . '99999999');
    is $mech->status, 404, "don't die on nonexistent page (valid id type)";
    $mech->get($page_uri . 'moo');
    is $mech->status, 404, "don't die on nonexistent page (invalid id type)";
};


subtest 'PageColumn' => sub {
    login('testuser');
    $mech->get('/user/testuser');

    # GET pagecolumn/list
    my ($page_uri) = $mech->find_all_links(
        url_regex => qr{/user/testuser/dataset/\d+/page/\d+$}
    );
    $mech->get($page_uri);
    my ($pagecol_list_uri) = $mech->find_all_links(
        url_regex => qr{/user/testuser/dataset/\d+/page/\d+/column$}
    );
    $mech->get_ok($pagecol_list_uri, 'can get PageColumn list');

    # POST pagecolumn/list
    my $pagecol_uri = add_new_object_ok({
        object => 'page column', list_uri => $pagecol_list_uri,
        form_name => 'add_page_column_form',
        form_args => {
            'page_column.title' => 'Chaang Column',
            'x-tunneled-method' => 'POST',
        }, page_uri_re => qr{/user/testuser/dataset/\d+/page/\d+/column/\d+},
    });

    # fixme: PUT    pagecolumn/list

    # DELETE pagecolumn/list
    $mech->delete($pagecol_list_uri->url(), {},);
    is $mech->status(), 405, 'no DELETE to page_column/list';
    $mech->post($pagecol_list_uri->url(), {'x-tunneled-method' => 'DELETE'});
    is $mech->status(), 405, 'no tunneled DELETE to page_column/list';

    # PUT pagecolumn/object
    $mech->get($pagecol_uri);
    puts_ok("page_column", $pagecol_uri, 'pagecol_form', {
        'page_column.title' => 'Chaang Column Update',
    });

    # GET pagecolumn/object
    $mech->get($pagecol_list_uri);
    $mech->follow_link_ok({
        url_regex => qr{/page/\d+/column/\d+},
    }, 'can get all pagecolumn links');

    # POST page_column/object
    $mech->post($pagecol_uri, {},);
    is $mech->status(), 405, 'no POST to page_columnt/object';

    # DELETE pagecolumn/object
    my ($pagecol_id) = ($pagecol_uri =~ m{(\d+)$});
    delete_ok({
        object => 'page column', object_id => $pagecol_id,
        object_uri => $pagecol_uri, list_uri => $pagecol_list_uri,
        form_prefix => 'delete_page_column_',
    });

    # GET  page_column/bad_object
    $mech->get($pagecol_uri . '99999999');
    is $mech->status, 404, "don't die on nonexistent page (valid id type)";
    $mech->get($pagecol_uri . 'moo');
    is $mech->status, 404, "don't die on nonexistent page (invalid id type)";
};


subtest 'Public Pages' => sub {
    login('testuser');
    $mech->get_ok('/user/testuser/dataset/1');
    $mech->post_ok('/user/testuser/dataset/1', {
        'dataset.permission' => 'public',
        'x-tunneled-method'  => 'PUT',
    });
    $mech->get_ok('/user/testuser/dataset/1/page/1');
    $mech->post_ok('/user/testuser/dataset/1/page/1', {
        'page.permission' => 'public',
        'x-tunneled-method'  => 'PUT',
    });
    logout();

    $mech->get_ok('/page', 'can get public page list');
    my $page_uri = get_link_like_ok('public page', qr{/page/1});
    $mech->get_ok($page_uri);

    $mech->get('/page/39873459345');
    like $mech->uri, qr{/page}, 'Sent back to list page';
};


subtest 'Permissions' => sub {
    login('testuser');
    $mech->get_ok('/user/testuser/dataset/1');
    $mech->post_ok('/user/testuser/dataset/1', {
        'dataset.permission' => 'public',
        'x-tunneled-method'  => 'PUT',
    });
    logout();
    $mech->get_ok('/user/testuser', q{logged-out user can visit testuser's overview});
    my ($ds_link) = $mech->find_all_links(
        url_regex => qr{/user/testuser/dataset/\d+}
    );
    my $ds_id = ($ds_link->url =~ m{/dataset/(\d+)});
    $mech->get_ok("/user/testuser/dataset/$ds_id", "public can see public dataset");
    redirects_to_ok("/user/testuser/dataset/$ds_id/column", "/login");
    $mech->post("/user/testuser/dataset/$ds_id", {'x-tunneled-method' => 'PUT',},);
    like $mech->uri, qr{login}, 'public not allowed to PUT on dataset, redired to login';

    login('newuser');
    $mech->get_ok("/user/testuser/dataset/$ds_id", "newuser can see testuser's dataset");
    redirects_to_ok("/user/testuser/dataset/$ds_id/column", "/user/newuser");
    $mech->post("/user/testuser/dataset/$ds_id", {'x-tunneled-method' => 'PUT',},);
    like $mech->uri, qr{/user/newuser}, 'other user not allowed to PUT on dataset, redired to their page';
};


subtest 'Page Cloning' => sub {

     # load clone1.xls, clone2.xls, and formatted page for clone1
    t::DB::load_fixtures('clone_set');

    my $ds_rs = t::DB::get_schema()->resultset('Dataset');
    my $clone1_ds = $ds_rs->find({name => 'IMDB Top 5'});
    my $clone2_ds = $ds_rs->find({name => 'IMDB Bottom 5'});
    my @pages = map {$_->pages->all} ($clone1_ds, $clone2_ds);

    login('testuser');
    $mech->get('/user/testuser/dataset/'. $clone2_ds->id);

    my $cloneable_page = $clone1_ds->pages_rs->search({title => {like => '%All Time'}})->first;
    $mech->submit_form(
        form_name => 'clone_existing_page',
        fields => {
            'page.clone_from' => $cloneable_page->id,
        },
    );
    like $mech->uri, qr{page/\d+}, 'got new page page';

};


# These tests are a bit gratuitious and don't really fit anywhere
# else.  It's mostly about trying to achieve 100% test coverage.
subtest 'Complete Coverage' => sub {
    login('testuser');
    $mech->get('/user/testuser');

    # test for error handling of ::Controller::Role::ExtractParams
    $mech->get('/user/testuser/dataset/1');
    $mech->post_ok(
        $mech->uri,
        { 'dataset.name' => 'boo', 'x-tunneled-method' => 'PUT', 'dataset.notes' => undef, },
        'can update dataset w/ undef param',
    );
    $mech->form_name('dataset_edit');
    my ($ds_input) = $mech->grep_inputs({name => qr/^dataset\.notes$/});
    is $ds_input->value, q{}, "ExtractParams sets undef parameter to q{}";
};


done_testing();



sub login {
    my ($user) = @_;
    logout();
    $mech->get('/login');
    $mech->submit_form(
        form_name => 'login_form',
        fields => {
            username => $users{$user}->{username},
            password => $users{$user}->{password},
        },
    );
}

sub logout {
    $mech->get('/logout');
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


sub puts_ok {
    my ($object, $edit_uri, $form_name, $put_args) = @_;

    $mech->form_name($form_name);
    $mech->get_ok($edit_uri, "can get $object edit page");
    # PUT dataset/object
    $mech->post_ok(
        $mech->uri,
        { %$put_args, 'x-tunneled-method' => 'PUT', },
        "can update $object",
    );
    $mech->get($edit_uri);
    $mech->form_name($form_name);
    while (my ($k, $v) = each %$put_args) {
        my ($ds_input) = $mech->grep_inputs({name => qr/^$k$/});
        is $ds_input->value, $v, "$k has been updated";
    }
}


sub get_link_like_ok {
    my ($object_descr, $uri_qr) = @_;
    my @links = $mech->find_all_links(url_regex => $uri_qr);
    ok @links, "found links to $object_descr lists";
    $mech->get_ok($links[0], "can get $object_descr page");
    return $links[0]->url;
}


sub delete_ok {
    my ($args) = @_;
    $mech->get($args->{list_uri});
    $mech->content_like(qr{$args->{object_uri}}, "$args->{object} exists");
    $mech->submit_form_ok({
        form_name => $args->{form_prefix} . $args->{object_id},
    }, "delete the $args->{object}");
    $mech->content_unlike(qr{$args->{object_uri}}, "$args->{object} no longer exists");
}


sub add_new_object_ok {
    my ($args) = @_;
    $mech->get($args->{list_uri});
    $mech->submit_form_ok({
        form_name => $args->{form_name},
        fields    => $args->{form_args},
    }, "add new $args->{object}");
    my $new_uri = $mech->uri;
    like $new_uri, qr{$args->{page_uri_re}},
        qq{got new $args->{object}'s edit page};
    return $new_uri;
}


# These methods test the user feedback messages after submitting a
# form.  user_feedback_like() is the generic method, tests should use
# one of the other user_*_like methods instead.
#
# This method will attempt to submit $form_args to the form named
# $form_name on the current page. It tests to make sure the request
# submits ok (i.e. no 500 'Internal Server Error').  It then retreives
# the standard feedback widget for the given feedback type and
# compares its contents against the $errmsg regex.
sub user_feedback_like {
    my ($feedback_type, $errmsg) = @_;
    my $sel = HTML::Selector::XPath::Simple->new($mech->content);
    my @all_elements = $sel->select('div.' . $alert_classes{$feedback_type});
    my $page_error = pop @all_elements;
    like $page_error, $errmsg, 'got correct error message';
}
sub user_error_like   { user_feedback_like('error',   @_); }
sub user_notice_like  { user_feedback_like('notice',  @_); }
sub user_success_like { user_feedback_like('success', @_); }
sub user_warning_like { user_feedback_like('warning', @_); }


# fetch emails from the Email::Sender test queue, then clear queue
sub get_emails {
    my @emails = Email::Sender::Simple->default_transport->deliveries;
    Email::Sender::Simple->default_transport->clear_deliveries;
    return @emails;
}
