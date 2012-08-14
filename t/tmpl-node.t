#/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Judoon::Tmpl::Factory;
use Judoon::Tmpl::Node::Text;
use Judoon::Tmpl::Node::Variable;
use Judoon::Tmpl::Node::Newline;
use Judoon::Tmpl::Node::VarString;
use Judoon::Tmpl::Node::Link;


my @node_types = qw(Text Variable Newline VarString Link);
my $varstring_args = {
    varstring_type    => 'static',
    text_segments     => ['foo','baz'],
    variable_segments => ['bar'],
};
my %node_args  = (
    Text      => {value => 'foo',},
    Variable  => {name => 'bar'},
    Newline   => {},
    VarString => $varstring_args,
    Link      => {url => $varstring_args, label => $varstring_args,},
);

my $moose_type_error = qr{validation failed}i;
my $yada_yada_error  = qr{unimplemented}i;


subtest '::Factory' => sub {
    for my $node_type (@node_types) {
        isa_ok build_node({
            type => lc($node_type), %{$node_args{$node_type}},
        }), "Judoon::Tmpl::Node::$node_type";
    }

    like exception { build_node({type => 'moo'}); }, qr/unrecognized node type/i,
        'build_node() dies w/ unknown node type';
};

subtest '::Node::Text' => sub {
    ok my $node = Judoon::Tmpl::Node::Text->new($node_args{Text}),
        'can create Text node';
    is $node->type, 'text', 'type is correct';
    is $node->value, 'foo', 'value is correct';
    is_deeply $node->decompose, $node, 'Text node decomposes to self';
};

subtest '::Node::Variable' => sub {
    ok my $node = Judoon::Tmpl::Node::Variable->new($node_args{Variable}),
        'can create Variable node';
    is $node->type, 'variable', 'type is correct';
    is $node->name, 'bar', 'name is correct';
    is_deeply $node->decompose, $node, 'Variable node decomposes to self';
};

subtest '::Node::Newline' => sub {
    ok my $node = Judoon::Tmpl::Node::Newline->new($node_args{Newline}),
        'can create Newline node';
    is $node->type, 'newline', 'type is correct';
    my @decomp = $node->decompose;
    is @decomp, 1, 'Newline node decomposes to one node';
    is $decomp[0]->type, 'text', '  ...which is a Text node';
    is $decomp[0]->value, '<br>', '  ...with an HTML <br> tag';
};

subtest '::Node::VarString' => sub {
    ok my $node = Judoon::Tmpl::Node::VarString->new($node_args{VarString}),
        'can create VarString node';
    is $node->type, 'varstring', 'type is correct';

    my @decomp = $node->decompose;
    is @decomp, 3, 'VarString node decomposes to three nodes';
    is $decomp[0]->type, 'text', '  ...first is a Text node';
    is $decomp[0]->value, 'foo', '  ...with correct value';
    is $decomp[1]->type, 'variable', '  ...second is a Variable node';
    is $decomp[1]->name, 'bar', '  ...with correct name';
    is $decomp[2]->type, 'text', '  ...third is a Text node';
    is $decomp[2]->value, 'baz', '  ...with correct value';

    like exception { Judoon::Tmpl::Node::VarString->new({
        %{$node_args{VarString}}, varstring_type => 'badtype',
    }); }, $moose_type_error, 'VarString dies on bad varstring_type';
};


subtest '::Node::Link' => sub {
    ok my $node = Judoon::Tmpl::Node::Link->new($node_args{Link}),
        'can create Link node';
    is $node->type, 'link', 'type is correct';

    my @decomp = $node->decompose;
    my $type_string = join ',', map {$_->type} @decomp;
    is $type_string, 'text,text,variable,text,text,text,variable,text,text',
        'Link decomposes to correct types';
    my $outstring = join q{},
        map {$_->type eq 'text' ? $_->value : '{'.$_->name.'}'} @decomp;
    is $outstring, '<a href="foo{bar}baz">foo{bar}baz</a>',
        '  ...with correct content';

    like exception { Judoon::Tmpl::Node::Link->new({
        url   => $varstring_args,
        label => {%$varstring_args, varstring_type => 'badtype',},
    }); }, $moose_type_error, 'Link dies on bad varstring_type';
};


# Here are some tests for error-checking provided by
# Method::Signatures. M::S tests' cover this, but Devel::Cover can't
# detect that.  We test it here to get that lovely, lovely field of
# green in our coverage report.
subtest 'Making Devel::Cover happy' => sub {
    for my $type (@node_types) {
        like exception {
            "Judoon::Tmpl::Node::$type"->new($node_args{$type})->decompose('moo');
        }, qr{too many arguments}i,
        "decompose for ::$type dies w/ too many args";
    }

    my $node = Judoon::Tmpl::Node::Link->new($node_args{Link});
    for my $make_type (qw(text variable)) {
        my $method = "make_${make_type}_node";
        like exception { $node->$method() }, qr{missing required argument}i,
            "::Role::Compostion::${method} dies w/ too few args";
        like exception { $node->$method('foo','bar') },
            qr{too many arguments}i,
            "::Role::Compostion::${method} dies w/ too many args";
    }
};


done_testing();
