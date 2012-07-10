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
fixtures_ok( sub {
    my ($schema) = @_;
    $schema->resultset('User')->create_user({
        username => 'testuser', password => 'testuser',
        name => 'Test User', email_address => 'testuser@example.com',
    });
} );


# start test server
my $mech = Test::WWW::Mechanize::Catalyst->new(
    catalyst_app => 'Judoon::Web',
);
ok $mech, 'created test mech' or BAIL_OUT;


# START TESTING!!!!

subtest 'Basic Tests' => sub {
    $mech->get_ok('/', 'get frontpage');
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
        like $mech->uri, qr{/user/newuser/dataset/list},
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


};



unlink $TEST_CONF_FILE if (-e $TEST_CONF_FILE);
done_testing();


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
