use strict;
use warnings;
use Test::More;


use Catalyst::Test 'Judoon::Web';
use Judoon::Web::Controller::API::Dataset;

ok( request('/api/dataset')->is_success, 'Request should succeed' );
done_testing();
