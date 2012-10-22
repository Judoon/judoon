#/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Judoon::Tmpl;

{
    my $tmpl;
    ok !exception { $tmpl = Judoon::Tmpl->new },
        'Can create a new empty Judoon::Tmpl';
    is_deeply $tmpl->nodes, [], 'initial nodelist is empty';
}

done_testing();
