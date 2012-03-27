use strict;
use warnings;
use Test::More;


use Catalyst::Test 'Judoon::Web';
use Judoon::Web::Controller::API::TemplateTranslator;

ok( request('/api/template')->is_success, 'Request should succeed' );
done_testing();
