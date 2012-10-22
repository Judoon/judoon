#/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Judoon::Tmpl;

ok !exception { Judoon::Tmpl->new }, 'Can create a new empty Judoon::Tmpl';


done_testing();
