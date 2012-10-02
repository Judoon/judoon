use strict;
use warnings;

BEGIN {
    if ($ENV{PLACK_ENV} eq 'development') {
        $ENV{JUDOON_WEB_DEBUG}   = 1;
        $ENV{DBIC_TRACE}         = 1;
        $ENV{DBIC_TRACE_PROFILE} = 'console';
    }
    elsif ($ENV{PLACK_ENV} eq 'test_deploy') {
        $ENV{JUDOON_WEB_DEBUG}   = 1;
        $ENV{DBIC_TRACE}         = 1;
        $ENV{DBIC_TRACE_PROFILE} = 'console_monochrome';
    }

}

use Judoon::Web;

my $app = Judoon::Web->apply_default_middlewares(Judoon::Web->psgi_app);
$app;

