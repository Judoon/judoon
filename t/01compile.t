#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use Module::Pluggable search_path => [ qw(Judoon) ];

# Judoon::Web uses HTML::String::TT, which warns if loaded after
# Template.  Make sure we load Judoon::Web before any other modules.
my @modules = grep {$_ ne 'Judoon::Web'} __PACKAGE__->plugins;
require_ok( 'Judoon::Web' );
require_ok( $_ ) for sort @modules;

done_testing;
