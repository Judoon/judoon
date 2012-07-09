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
    subtest 'Signup' => sub {
        $mech->get_ok('/signup', 'got signup page');
        my %newuser = (
            'user.username' => 'newuser', 'user.password' => 'newuserisme',
            'user.confirm_password' => 'newuserisme',
            'user.email_address' => 'newuser@example.com',
            'user.name' => 'New User',
        );
        $mech->post_ok('/signup', \%newuser, 'can create new user');
        like $mech->uri, qr{/login},
            '  ...and new user is asked to login';

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
