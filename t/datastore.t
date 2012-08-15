#/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

my $datastore_tmp_dir;
BEGIN {
    $datastore_tmp_dir = File::Temp->newdir();
    $ENV{JUDOON_DATASTORE_DATA_DIR} = $datastore_tmp_dir;
    use Judoon::DataStore::SQLite;
}


subtest 'making new user datastore' => sub {
    my $owner = 'cellmigration';

    like exception { Judoon::DataStore::SQLite->new(); },
        qr{missing required arg}i, q{Can't create datastore w/o owner};

    my $datastore = Judoon::DataStore::SQLite->new({owner => $owner});;
    ok !$datastore->exists, 'datastore does not yet exist';
    ok $datastore->init, 'can create new datastore';
    ok $datastore->exists, 'datastore now exists';

    like exception { $datastore->init; }, qr/datastore already exists/i,
      q{can't re-init datastore};

};



done_testing();


END {
    $datastore_tmp_dir = undef;
}
