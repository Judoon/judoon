use strict;
use warnings;

use Judoon::Web;

my $app = Judoon::Web->apply_default_middlewares(Judoon::Web->psgi_app);
$app;

