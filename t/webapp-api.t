#!/usr/bin/env perl

use strict;
use warnings;

use lib q{t/lib};

use Test::More;
use Test::JSON;
use t::DB;

use Data::Printer;
use JSON qw(decode_json);

# start test server
my $mech = t::DB::new_mech();
$mech->add_header( 'Content-Type' => 'application/json' );
ok $mech, 'created test mech' or BAIL_OUT;


# START TESTING!!!!

subtest 'Basic Tests' => sub {

    for my $uri (qw(/api /api/)) {
        $mech->get_ok($uri, "get $uri");
        is $mech->uri, 'http://localhost/', '  ...redirects to root';
    }

    $mech->get_ok('/api/datasetdata', 'get /api/datasetdata');

    my $schema = t::DB::get_schema();
    my $ds = $schema->resultset('Dataset')->first;

    my $ds_id = $ds->id;
    $mech->get_ok("/api/datasetdata/$ds_id");
    is_valid_json($mech->content, '  ...response is valid json');
    my $data = decode_json($mech->content);
    is_deeply $data->{tmplData}[0],
        {name => 'Chewie', gender => 'male', age => 5},
            '   ...expected content';
};


done_testing();

