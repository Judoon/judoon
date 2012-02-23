#!/usr/bin/env perl

use strict;
use warnings;
use autodie;

use Test::More;

use_ok 'Judoon::Template::Translator' or BAIL_OUT;

my $jtt = Judoon::Template::Translator->new;


subtest 'translate' => sub {

    my $html = <<'HTML1';

HTML1
    my $template = ;


};

done_testing;
