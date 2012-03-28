#/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::DBIx::Class {
    schema_class => 'Judoon::DB::User::Schema',
    connect_info => ['dbi:SQLite:dbname=t/var/testdb.sqlite','',''],
};
require Catalyst::Test;


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
    $schema->resultset('User')->create({
        login => 'testuser', name => 'Test User',
    });
} );


# start test server
Catalyst::Test->import('Judoon::Web');


# basic test
action_ok('/', 'root page');
action_redirect('/user/testuser', 'ask for testuser without login redirects');


# fixme: can't login until logins are db-driven


unlink $TEST_CONF_FILE if (-e $TEST_CONF_FILE);
done_testing();

