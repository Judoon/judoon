#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use Module::Pluggable search_path => [ qw(Judoon) ];

require_ok( $_ ) for sort __PACKAGE__->plugins;

done_testing;
