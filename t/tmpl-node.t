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


subtest '::Node' => sub {
    use Judoon::Tmpl::Node;
    ok my $node = Judoon::Tmpl::Node->new, 'can create plain Node';
    ok exception { $node->type; }, '->type on a plain Node dies';
    ok exception { $node->decompose; }, '->decompose on a plain Node dies';
};


subtest '::Node::Text' => sub {
    use Judoon::Tmpl::Node::Text;

    ok my $node = Judoon::Tmpl::Node::Text->new({value => 'foo'}),
        'can create Text node';
    is $node->type, 'text', 'type is correct';
    is $node->value, 'foo', 'value is correct';
    is_deeply $node->decompose, $node, 'Text node decomposes to self';
    ok exception { $node->decompose('moo'); },
        'decompose dies w/ too many args';
};


subtest '::Node::Variable' => sub {
    use Judoon::Tmpl::Node::Variable;

    ok my $node = Judoon::Tmpl::Node::Variable->new({name => 'foo'}),
        'can create Variable node';
    is $node->type, 'variable', 'type is correct';
    is $node->name, 'foo', 'name is correct';
    is_deeply $node->decompose, $node, 'Variable node decomposes to self';
    ok exception { $node->decompose('moo'); },
        'decompose dies w/ too many args';
};


subtest '::Node::Newline' => sub {
    use Judoon::Tmpl::Node::Newline;

    ok my $node = Judoon::Tmpl::Node::Newline->new({}),
        'can create Newline node';
    is $node->type, 'newline', 'type is correct';
    my @decomp = $node->decompose;
    is @decomp, 1, 'Newline node decomposes to one node';
    is $decomp[0]->type, 'text', '  ...which is a Text node';
    is $decomp[0]->value, '<br>', '  ...with an HTML <br> tag';
    ok exception { $node->decompose('moo'); },
        'decompose dies w/ too many args';
};





done_testing();
