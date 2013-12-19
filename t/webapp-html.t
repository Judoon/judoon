#!/usr/bin/env perl


BEGIN {
    $ENV{EMAIL_SENDER_TRANSPORT} = 'Test';
}

use Config::General;
use Data::Printer;
use Email::Sender::Simple;
use File::Temp qw(tempdir);
use FindBin qw($Bin);
use HTML::Selector::XPath::Simple;
use List::AllUtils ();

use Test::Roo;
use lib 't/lib';
with 't::Role::Schema', 't::Role::Mech', 't::Role::WebApp',
    'Judoon::Role::JsonEncoder';


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


after setup => sub {
    my ($self) = @_;
    $self->load_fixtures(qw(init basic));

    $self->users->{newuser} = {
        username => 'newuser', password => 'newuserisme',
        name => 'New User', email_address => 'newuser@example.com',
    };

};


test 'Basic Tests' => sub {
    my ($self) = @_;

    $self->mech->get_ok('/', 'get frontpage');
    $self->mech->get_ok('/placeholder', 'get placeholder page');
    $self->mech->get_ok('/api');
    $self->mech->get_ok('/get_started');
    $self->mech->get_ok('/about');
    $self->mech->get_ok('/news');
};


test 'Login / Logout' => sub {
    my ($self) = @_;

    $self->redirects_to_ok('/settings/profile', '/login');

    my %credentials = (
        username => $self->users->{testuser}{username},
        password => $self->users->{testuser}{password},
    ),
    $self->mech->get_ok('/login', 'get login page');

    # bad login
    $self->mech->submit_form_ok({
        form_name => 'login_form',
        fields    => {%credentials, password => 'badpass'},
    }, "can submit login form with bad data without error");
    $self->user_error_like(qr{Username or password is incorrect}i);
    $self->redirects_to_ok('/settings/profile', '/login');

    # good login
    $self->mech->submit_form_ok({
        form_name => 'login_form',
        fields => \%credentials,
    }, 'submitted login okay');
    $self->no_redirect_ok('/settings/profile', 'can get to profile after login');

    # can't re-login
    $self->redirects_to_ok('/login', '/users/testuser');
    $self->mech->post('/login', \%credentials,);
    like $self->mech->uri, qr{/users/testuser$},
        'posting to login redirects to overview';

    $self->mech->get_ok('/get_started', 'get get_started page while logged-in');

    # logout
    $self->mech->get_ok('/logout', 'can logout okay');
    $self->redirects_to_ok('/settings/profile', '/login');
};


test 'Account' => sub {
    my ($self) = @_;

    subtest 'Account List' => sub {
        $self->logout();
        $self->redirects_to_ok('/account', '/login');
        $self->my_login('testuser');
        $self->redirects_to_ok('/account', '/users/testuser');
    };


    my $newuser_canon = $self->users->{newuser};
    my %newuser = map {; "user.$_" => $newuser_canon->{$_}}
        keys %$newuser_canon;

    subtest 'Signup' => sub {
        $self->mech->get_ok('/account/signup', 'got signup page');

        $newuser{'user.confirm_password'} = 'wontmatch';
        $self->mech->post_ok('/account/signup', \%newuser);
        $self->mech->content_like(
            qr{passwords do not match}i,
            q{can't create user w/o matching passwords},
        );

        $newuser{'user.confirm_password'} = $newuser{'user.password'};
        $newuser{'user.username'}         = 'testuser';
        $self->mech->post_ok('/account/signup', \%newuser);
        $self->mech->content_like(
            qr{this username is already taken}i,
            q{can't create user w/ same name as current user},
        );


        $newuser{'user.username'} = 'newuser';
        $self->mech->post_ok('/account/signup', \%newuser, 'can create new user');
        like $self->mech->uri, qr{/users/newuser},
            '  ...and send new user to their datasets';
    };

    subtest 'Settings' => sub {
        $self->mech->get_ok('/settings', 'Got settings page');
        $self->mech->links_ok(
            [$self->mech->find_all_links(url_regex => qr{/settings/})],
            'links are good',
        );
    };

    subtest 'Profile' => sub {
        $self->mech->get_ok('/settings/profile', 'get user profile');
        $self->mech->post_ok(
            '/settings/profile',
            {
                'user.email_address' => 'newuser@example.com',
                'user.name'          => 'New Name',
            },
            'can update profile',
        );
        $self->mech->form_name('profile_form');
        my ($name_input) = $self->mech->grep_inputs({name => qr/^user\.name$/});
        is $name_input->value, 'New Name', 'phone number has been updated';

        # broken: we're way too permissive right now
        # $self->mech->post_ok(
        #     '/settings/profile',
        #     {
        #         'user.email_address' => undef,
        #         'user.name'          => 'New Name',
        #         'user.phone_number'  => '555-5505',
        #     },
        # );
        # $self->mech->content_like(qr{unable to update profile}i, q{cant duplicate email address});
    };

    subtest 'Password' => sub {
        $self->mech->get_ok('/settings/password', 'get user password change');

        $self->mech->submit_form_ok({
            form_name => 'password_form',
            fields    => {old_password => $newuser{'user.password'},},
        }, 'submit_ok: need all three fields');
        $self->user_error_like(qr/New password must not be blank/i);

        $self->mech->submit_form_ok({
            form_name => 'password_form',
            fields    => {
                old_password => 'incorrect', new_password => 'boobooboo',
                confirm_new_password => 'boobooboo',
            },
        }, q{submit_ok: can't change password when old password is wrong},);
        $self->user_error_like(qr/old password is incorrect/i);

        $self->mech->submit_form_ok({
            form_name => 'password_form',
            fields    => {
                old_password => $newuser{'user.password'},
                new_password => 'boo',
                confirm_new_password => 'boo',
            },
        }, 'submit_ok: cant update password with invalid password',);
        $self->user_error_like(qr/Invalid password/i);

        $self->mech->submit_form_ok({
            form_name => 'password_form',
            fields    => {
                old_password         => $newuser{'user.password'},
                new_password         => 'newuserisstillme',
                confirm_new_password => 'newuserisstillme',
            },
        }, 'submit_ok: able to update password');
        $self->user_success_like(qr/Your password has been updated/);

        $newuser_canon->{password} = 'newuserisstillme';
    };

};


test 'Password Reset' => sub {
    my ($self) = @_;

    $self->logout();

    my $pass_resend_uri = '/account/password_reset';
    $self->mech->get_ok($pass_resend_uri, 'get password resend page ok');

    subtest 'Request Failures' => sub {

        my @errors = (
            [q{no password reset w/ bad email},    {email_address => 'nope@nope.com'},],
            [q{no password reset w/ bad username}, {username => 'doesnt_exist'},],
            [q{no password reset w/o args},        {},],
        );
        for my $error (@errors) {
            my ($msg, $args,) = @$error;
            $self->mech->submit_form_ok({
                form_name => 'resend_password_form', fields => $args,
            }, "submit_ok: $msg");
            $self->user_error_like(qr{Couldn't find an account});
        }
    };

    my $bad_reset_uri;
    subtest 'Request Successes' => sub {
        my @wins = (
            [
                'can request password reset by email',
                {email_address => $self->users->{testuser}{email_address}},
            ],
            [
                'can request password reset by username',
                {username => 'testuser'},
            ],
        );

        for my $win (@wins) {
            my ($msg, $args) = @$win;
            $self->mech->get($pass_resend_uri);
            $self->mech->submit_form_ok({
                form_name => 'resend_password_form', fields => $args,
            }, "submit_ok: $msg");
            $self->user_notice_like(qr{email has been sent});
            like $self->mech->uri, qr{/login$}, '..then sent to login page';

            my ($reset_email) = get_emails();
            my $body = $reset_email->{email}->as_string;
            like $body, qr{judoon password reset}i, 'password reset email sent';
            my ($reset_uri) = ($body =~ m{http://[^/]+(/\S+)});
            $bad_reset_uri  ||= $reset_uri . 'totally_bogus';

            # make sure we can log in as normal user even after passwd reset
            $self->my_login('testuser');
            $self->redirects_to_ok($pass_resend_uri, '/users/testuser',);
            $self->logout();

            $self->mech->get_ok($reset_uri, 'can get uri reset page');
            like $self->mech->content(), qr{Confirm New Password},
                '  ...make sure we have correct page';
            unlike $self->mech->content(), qr{Old Password},
                '  ...dont ask for old password';

            $self->mech->submit_form_ok({
                form_name => 'password_form',
                fields    => {
                    new_password         => 'this',
                    confirm_new_password => 'that',
                },
            }, "submit_ok: can't change password when new passwords don't match");
            $self->user_error_like(qr/passwords do not match/i);

            $self->mech->submit_form_ok({
                form_name => 'password_form',
                fields    => {
                    new_password         => '',
                    confirm_new_password => '',
                },
            }, q{can't change password when one of new passwords is blank},);
            $self->user_error_like(qr/password must not be blank/i);

            $self->mech->submit_form_ok({
                form_name => 'password_form',
                fields    => {
                    new_password         => 'this',
                    confirm_new_password => 'this',
                },
            }, q{can't change password when passwords are invalid},);
            $self->user_error_like(qr/invalid password/i);

            $self->mech->submit_form_ok({
                form_name => 'password_form',
                fields => {qw(new_password newpasswd confirm_new_password newpasswd)},
            }, 'submit password reset okay');
            like $self->mech->uri, qr{/users/testuser$}, 'sent to testuser overview page';

            $self->logout();
            $self->users->{testuser}{password} = 'newpasswd';
            $self->my_login('testuser');
            like $self->mech->uri, qr{/users/testuser}, 'Password successfully reset';
            $self->logout();

            $self->mech->get($reset_uri);
            like $self->mech->uri, qr{/login},
                'reset token deleted after successful password reset';
            $self->user_error_like(qr{No action found for token});
        }
    };

    subtest 'Reset Failures' => sub {
        $self->mech->get($bad_reset_uri);
        like $self->mech->uri(), qr{/login$},
            'bad login token sends you to the login page';
        $self->user_error_like(qr{No action found for token});

        # forcibly expire token and test app response
        $self->mech->get($pass_resend_uri);
        $self->mech->submit_form(
            form_name => 'resend_password_form',
            fields    => {username => 'testuser'},
        );
        my ($expired_reset_email) = get_emails();
        my $expired_reset_body = $expired_reset_email->{email}->as_string;
        my ($expired_reset_uri) = ($expired_reset_body =~ m{http://[^/]+(/\S+)});
        my ($expired_reset_token) = ($expired_reset_uri =~ m/value=(\S+)/);

        my $expired_token = $self->schema->resultset('Token')
            ->find({value => $expired_reset_token});
        $expired_token->expires( DateTime->new(year => 2000, day => 1, month => 1) );
        $expired_token->update;

        $self->mech->get($expired_reset_uri);
        like $self->mech->uri, qr{/account/password_reset},
            'expired reset tokens sends us back to login';
        $self->user_error_like(qr/your password reset token has expired/i);
    };

    # needed tests:
    #   sending email fails: resend_password_POST
    #     not sure how to do this, look at Email::Sender::Transport::Failable
};


test 'User List' => sub {
    my ($self) = @_;

    $self->logout();
    $self->redirects_to_ok('/users', '/login');
    $self->my_login('testuser');
    $self->redirects_to_ok('/users', '/users/testuser');
};


run_me();
done_testing();



sub my_login {
    my ($self, $user) = @_;
    $self->login($user, $self->users->{$user}{password});
}


sub redirects_ok {
    my ($self, $req_url) = @_;

    my $req_redir = $self->mech->requests_redirectable();
    $self->mech->requests_redirectable([]);
    $self->mech->get($req_url);
    is($self->mech->status(), 302, 'requests for ' . $req_url . ' are redirected');
    $self->mech->requests_redirectable($req_redir);
}

sub redirects_to_ok {
    my ($self, $req_url, $res_url) = @_;
    $self->redirects_ok($req_url);
    $self->mech->get_ok($req_url, 'Redirection for ' . $req_url . ' succeeded...');
    like($self->mech->uri(), qr/$res_url/, '  ...to correct url: ' . $res_url);
}

sub no_redirect_ok {
    my ($self, $req_url, $descr) = @_;
    $descr //= 'requests for ' . $req_url . ' are not redirected';

    my $req_redir = $self->mech->requests_redirectable();
    $self->mech->requests_redirectable([]);
    $self->mech->get($req_url);
    is $self->mech->status(), 200, $descr;
    $self->mech->requests_redirectable($req_redir);
}


# These methods test the user feedback messages after submitting a
# form.  $self->user_feedback_like() is the generic method, tests should use
# one of the other $self->user_*_like methods instead.
#
# This method will attempt to submit $form_args to the form named
# $form_name on the current page. It tests to make sure the request
# submits ok (i.e. no 500 'Internal Server Error').  It then retreives
# the standard feedback widget for the given feedback type and
# compares its contents against the $errmsg regex.
sub user_feedback_like {
    my ($self, $feedback_type, $errmsg) = @_;
    my $sel = HTML::Selector::XPath::Simple->new($self->mech->content);
    my @all_elements = $sel->select('div.' . $alert_classes{$feedback_type});
    my $page_error = pop @all_elements;
    like $page_error, $errmsg, 'got correct error message';
}
sub user_error_like   { shift->user_feedback_like('error',   @_); }
sub user_notice_like  { shift->user_feedback_like('notice',  @_); }
sub user_success_like { shift->user_feedback_like('success', @_); }
sub user_warning_like { shift->user_feedback_like('warning', @_); }


# fetch emails from the Email::Sender test queue, then clear queue
sub get_emails {
    my @emails = Email::Sender::Simple->default_transport->deliveries;
    Email::Sender::Simple->default_transport->clear_deliveries;
    return @emails;
}
