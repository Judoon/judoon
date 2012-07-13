#/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Judoon::Tmpl::Factory;

isa_ok build_node({type => 'text', value => 'foo'}),
    'Judoon::Tmpl::Node::Text';
isa_ok build_node({type => 'variable', name => 'foo'}),
    'Judoon::Tmpl::Node::Variable';
isa_ok build_node({type => 'link', label => {varstring_type=>'static',text_segments=>[],variable_segments=>[],}, url => {varstring_type=>'static',text_segments=>[],variable_segments=>[],},}),
    'Judoon::Tmpl::Node::Link';
isa_ok build_node({type => 'newline'}), 'Judoon::Tmpl::Node::Newline';
like exception { build_node({type => 'moo'}); }, qr/unrecognized node type/i,
    'build_node() dies w/ unknown node type';

done_testing();
