#/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::postgresql;

use DBI;
use Judoon::DataStore::Pg;
use Judoon::DataStore::SQLite;
use Path::Class qw(dir);


my $owner = 'cellmigration';
my $psql = Test::postgresql->new() or BAIL_OUT $Test::postgresql::errstr;
my @backends = (
    # backend  args_to_new()
    ['SQLite', {storage_dir => dir(File::Temp->newdir())},                 ],
    ['Pg',     {my_dsn => [$psql->dsn(dbname => 'template1'), '', '', {}]},],
);


for my $backend_args (@backends) {
    my ($backend, $obj_args) = @$backend_args;
    my $class = "Judoon::DataStore::$backend";

    subtest "init/exists for $class" => sub {

        my $no_owner_exc = exception { $class->new(%$obj_args); };
        like $no_owner_exc, qr{missing required arg}i,
            q{Can't create datastore w/o owner};

        my $datastore = $class->new({%$obj_args, owner => $owner});
        ok !$datastore->exists, 'datastore does not yet exist';
        is exception { $datastore->init }, undef, 'can create new datastore';
        ok $datastore->exists, 'datastore now exists';

        my $no_reinit_exc = exception { $datastore->init; };
        like $no_reinit_exc, qr/datastore already exists/i,
            q{can't re-init datastore};

        my $dsn = $datastore->my_dsn;
        ok my $dbh = DBI->connect(@$dsn), 'can connect to new database';
        $dbh->disconnect;

        if ($backend eq 'SQLite') {
            ok -f $datastore->db_path, 'see db in filesystem';
        }
    };


    subtest "adding data for $class" => sub {
        my $datastore = $class->new({%$obj_args, owner => $owner});
        ok $datastore->exists,
            'db persists after creating object is out of scope';

        $datastore->add_dataset('t/etc/data/basic.xls');
        $datastore->add_dataset('t/etc/data/basic2.xls');

        $datastore->dbh->disconnect; # delete when new SQLT is released
    };

}

done_testing();
