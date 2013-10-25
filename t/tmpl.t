#!/usr/bin/env perl

use utf8;

use Encode;
use Judoon::Tmpl;
use Test::Differences;
use Test::Fatal;

use Test::Roo;

use lib 't/lib';
with 'Judoon::Role::JsonEncoder', 't::Role::TmplFixtures';



test 'basic tests' => sub {
    my ($self) = @_;

    my $tmpl;
    ok !exception { $tmpl = Judoon::Tmpl->new },
        'Can create a new empty Judoon::Tmpl';
    is_deeply $tmpl->nodes, [], 'initial nodelist is empty';
};

test 'from / to formats' => sub {
    my ($self) = @_;

    my %method_map = qw(jstmpl jstmpl native native widgets data);
    my $formats = $self->get_tmpl_fixture('basic_equiv');
    for my $in_format (keys %$formats) {
        my $input = $formats->{$in_format};
        my $constructor = "new_from_" . $method_map{$in_format};
        ok my $tmpl = Judoon::Tmpl->$constructor($input),
            "can build Tmpl from $in_format";

        ok my @nodes = $tmpl->get_nodes, '  ..can get nodes';
        is scalar(@nodes), 4, '  ..node count is correct';
        is $tmpl->node_count, 4, '  ..and node_count agrees';
        is_deeply [$tmpl->node_types], [qw(text variable newline link)],
            '  ..with correct node types';

        is $nodes[0]->value, 'foo',     '  ..first node has correct value';
        is $nodes[1]->name,  'bar',     '  ..second node has correct name';
        is $nodes[2]->type,  'newline', '  ..third node isa newline';
        is $nodes[3]->type,  'link',    '  ..fourth node isa link';
        is_deeply [$tmpl->get_variables], ['bar', 'baz'],
            '  ..get_variables() returns correct variables';

        for my $out_format (keys %$formats) {
            my $output = $formats->{$out_format};
            my $output_method = "to_" . $method_map{$out_format};
            my $out_constructor = "new_from_" . $method_map{$out_format};
            ok my $out_tmpl = Judoon::Tmpl->$out_constructor(
                $tmpl->$output_method()
            ), "  ..can build Tmpl from its $out_format";

            is_deeply $tmpl->nodes, $out_tmpl->nodes,
                "  ..translates correctly to $out_format";
        }
    }


    # tests for specific formats
    unlike(Judoon::Tmpl->new_from_data($formats->{widgets})->to_native,
        qr{__CLASS__}, '__CLASS__ keys have been scrubbed from data');

    {
        my $perl_text    = '[{"type":"text","value":"resumé","formatting":[]}]';
        my $utf8_text    = encode("utf-8", $perl_text);
        my $utf8_to_utf8 = Judoon::Tmpl->new_from_native($utf8_text)
            ->to_native();

        my $output_canon;
        ok !exception { $output_canon = $self->decode_json($utf8_to_utf8); },
            "output is properly encoded as utf8";

        my $expected_canon = $self->decode_json($utf8_text);
        eq_or_diff $output_canon, $expected_canon,
            ' ..and has correct structure';
    }

    like exception { Judoon::Tmpl->new_from_jstmpl(); },
        qr/cannot parse undef input/i, 'new_from_jstmpl dies on no input';

    is_deeply( Judoon::Tmpl->new_from_jstmpl('')->to_data(), [],
        'empty string to new_from_jstmpl produces empty template');

    like exception { Judoon::Tmpl->_new_node([]); },
        qr{must be a hash}i, '_new_node dies on bad arg';

    like exception { Judoon::Tmpl->new_from_jstmpl('<div>bad tag</div>'); },
        qr{unsupported tag type}i, 'new_from_jstmpl dies on bad tag';

    like exception { Judoon::Tmpl->new_from_jstmpl('<a href="foo">bad <br> tag </a>'); },
        qr{html tags found inside <a></a>}i,
            'new_from_jstmpl with html inside <a>';

};


test 'node factory' => sub {
    my ($self) = @_;

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
    for my $node_type (@node_types) {
        my $node_class = "Judoon::Tmpl::Node::$node_type";

        isa_ok(Judoon::Tmpl->_new_node({
            type => lc($node_type), %{$node_args{$node_type}},
        }), $node_class);
    }

    like exception { Judoon::Tmpl->_new_node({type => 'moo'}); },
        qr/unrecognized node type/i,
            '_new_node() dies w/ unknown node type';
};



# Here are some tests for error-checking provided by Params::Validate.
# P::V tests' cover this, but Devel::Cover can't detect that.  We test
# it here to get that lovely, lovely field of green in our coverage
# report.
# subtest 'failures' => sub {
# 
#     # set up our error regexes
#     my $pv_missing_arg   = qr{mandatory parameters? .* missing in call to}i;
#     my $pv_wrong_arg     = qr{following parameter was passed .* but was not listed in the validation options}i;
#     my $ms_missing_arg   = qr{In call to .* missing required argument}i;
#     my $ms_too_many_args = qr{too many argument}i;
#     my %descrs = (
#         $ms_missing_arg => 'missing arg', $pv_wrong_arg => 'wrong arg',
#         $ms_too_many_args => 'too many args', $pv_missing_arg => 'missing arg',
#     );
# 
#     # failing inputs to Util::{translate,from_objects,to_objects}
#     my @fails = (
#         ['translate', [qw(from to)],                $pv_missing_arg,   ],
#         ['translate', [qw(to template)],            $pv_missing_arg,   ],
#         ['translate', [qw(from template)],          $pv_missing_arg,   ],
#         ['translate', [qw()],                       $pv_missing_arg,   ],
#         ['translate', [qw(from to template bogus)], $pv_wrong_arg,     ],
# 
#         ['from_objects', [qw()],                 $pv_missing_arg,    ],
#         ['from_objects', [qw(to)],               $pv_missing_arg,    ],
#         ['from_objects', [qw(objects)],          $pv_missing_arg,    ],
#         ['from_objects', [qw(to objects bogus)], $pv_wrong_arg,      ],
# 
#         ['to_objects', [qw()],                    $pv_missing_arg,    ],
#         ['to_objects', [qw(from)],                $pv_missing_arg,    ],
#         ['to_objects', [qw(template)],            $pv_missing_arg,    ],
#         ['to_objects', [qw(from template bogus)], $pv_wrong_arg,      ],
#     );
#     my %fail_args = (
#         from => 'Native', to => 'Native', template => '', objects => [],
#         bogus => '',
#     );
#     for my $failset (@fails) {
#         my ($method, $argset, $error) = @$failset;
#         like exception {
#             no strict 'refs';
#             $method->(map {$_ => $fail_args{$_}} @$argset);
#         }, $error, "calling $method w/ $descrs{$error}";
#     }

#     like exception { translate(
#         from => 'JQueryTemplate', to => 'JQueryTemplate', template => undef,
#     ); }, qr/cannot parse undef input/i, 'JQuery dies on undef input';

# };

test 'input validation' => sub {
    my ($self) = @_;

    my $no_new_on_self   = qr{Don't call .* on an object}i;
    my $arg_must_be_array = qr{Argument to .* must be an arrayref}i;
    my $pv_wrong_type = qr{Parameter.*which is not one of the allowed types}i;


    my $tmpl  = Judoon::Tmpl->new(nodes => []);
    my $class = 'Judoon::Tmpl';

    my @fails = (
        ['new_from_data',   [$tmpl, []], $no_new_on_self,],
        ['new_from_data',   [$class, {}], $arg_must_be_array,],

        ['new_from_native', [$tmpl,  '[]',             ], $pv_wrong_type],
        ['new_from_native', [$class, '{"type":"text"}',], $arg_must_be_array],

        ['new_from_jstmpl', [$tmpl, []], $no_new_on_self,],
    );

    my %descrs = (
        $no_new_on_self    => '$self instead of $class',
        $arg_must_be_array => 'non-array argument',
        $pv_wrong_type => 'wrong argument type',
    );


    for my $failset (@fails) {
        my ($method, $argset, $error) = @$failset;
        like exception {
            $argset->[0]->$method($argset->[1]);
        }, $error, "calling $method w/ $descrs{$error}";
    }
};

run_me();
done_testing();
