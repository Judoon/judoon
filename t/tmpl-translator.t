#/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Data::Section::Simple qw(get_data_section);
use Judoon::Tmpl::Factory;
use Judoon::Tmpl::Translator;

my $translator = Judoon::Tmpl::Translator->new;

subtest 'input validation' => sub {
    like exception {
        $translator->to_objects(from => 'BadDialect', template => '');
    }, qr{is not a valid dialect}i, 'dies w/ bad dialect to to_objects()';
    like exception {
        $translator->from_objects(to => 'BadDialect', objects => []);
    }, qr{is not a valid dialect}i, 'dies w/ bad dialect to from_objects()';
    # like exception {
    #     $translator->translate(from => 'JQueryTemplate', to => 'BadDialect', template => 'foo{{=bar}}');
    # }, qr{is not a valid dialect}i, 'dies w/ bad dialect for to in translate()';
    like exception {
        $translator->translate(from => 'BadDialect', to => 'Native', template => '');
    }, qr{is not a valid dialect}i, 'dies w/ bad dialect for from in translate()';

};

# Here are some tests for error-checking provided by
# Method::Signatures. M::S tests' cover this, but Devel::Cover can't
# detect that.  We test it here to get that lovely, lovely field of
# green in our coverage report.
subtest 'Making Devel::Cover happy' => sub {
    my $ms_wrong_arg     = qr{does not take \w+ as named argument}i;
    my $ms_missing_arg   = qr{missing required argument}i;
    my $ms_too_many_args = qr{too many argument}i;

    my %fail_args = (
        from => 'Native', to => 'Native', template => '', objects => [],
        bogus => '',
    );

    my @fails = (
        ['translate', [qw(from to)],                $ms_missing_arg,   ],
        ['translate', [qw(to template)],            $ms_missing_arg,   ],
        ['translate', [qw(from template)],          $ms_missing_arg,   ],
        ['translate', [qw()],                       $ms_missing_arg,   ],
        ['translate', [qw(from to template bogus)], $ms_wrong_arg,     ],
        ['translate', [qw(from to to template)],    $ms_too_many_args, ],

        ['from_objects', [qw()],                 $ms_missing_arg,    ],
        ['from_objects', [qw(to)],               $ms_missing_arg,    ],
        ['from_objects', [qw(objects)],          $ms_missing_arg,    ],
        ['from_objects', [qw(to objects bogus)], $ms_wrong_arg,      ],
        ['from_objects', [qw(to objects to)],    $ms_too_many_args,  ],

        ['to_objects', [qw()],                    $ms_missing_arg,    ],
        ['to_objects', [qw(from)],                $ms_missing_arg,    ],
        ['to_objects', [qw(template)],            $ms_missing_arg,    ],
        ['to_objects', [qw(from template bogus)], $ms_wrong_arg,      ],
        ['to_objects', [qw(from template from)],  $ms_too_many_args,  ],
    );

    my %descrs = (
        $ms_missing_arg => 'missing arg', $ms_wrong_arg => 'wrong arg',
        $ms_too_many_args => 'too many args',
    );

    for my $failset (@fails) {
        my ($method, $argset, $error) = @$failset;
        like exception {
            $translator->$method(map {$_ => $fail_args{$_}} @$argset);
        }, $error, "calling $method w/ $descrs{$error}";
    }


    for my $dialect ($translator->dialects()) {
        my $dialect_obj = "Judoon::Tmpl::Translator::Dialect::$dialect"->new;
        like exception {$dialect_obj->parse()}, $ms_missing_arg,
            "::Dialect::${dialect}::parse w/ no args";
        like exception {$dialect_obj->parse('moo','moo')}, $ms_too_many_args,
            "::Dialect::${dialect}::parse w/ too many args";
        like exception {$dialect_obj->produce()}, $ms_missing_arg,
            "::Dialect::${dialect}::produce w/ no args";
        like exception {$dialect_obj->produce([],[])}, $ms_too_many_args,
            "::Dialect::${dialect}::produce w/ too many args";
    }

};



subtest 'translation test' => sub {

    my @test_objects = (
        new_text_node({value => 'foo'}),
        new_variable_node({name => 'bar'}),
        new_newline_node(),
        new_link_node({
            url => {
                varstring_type    => 'static',
                text_segments     => ['foo',],
                variable_segments => ['',],
            },
            label => {
                varstring_type    => 'variable',
                text_segments     => ['foo','bar',],
                variable_segments => ['baz','',],
            },
        }),
    );

    for my $dialect ($translator->dialects()) {
        ok my $tmpl = $translator->from_objects(
            to => $dialect, objects => \@test_objects
        ), "$dialect can build a template from objects";
        ok my @back_objects = $translator->to_objects(
            from => $dialect, template => $tmpl,
        ), "dialect can build objects from a template";
        is_deeply \@back_objects, \@test_objects,
            '  ...and the object set is the same';
    }

    my @comparisons = (
        ['JQueryTemplate', get_data_section('jquery.txt'), 'Native', get_data_section('native.json'), 'complex',],
        ['JQueryTemplate', q{}, 'Native', '[]', 'empty'],
    );
    for my $compare (@comparisons) {
        my ($dialect1, $input1, $dialect2, $input2, $descr) = @$compare;

        my $d1_to_d1 = $translator->translate(
            from => $dialect1, to => $dialect1, template => $input1,
        );
        my $d2_to_d1 = $translator->translate(
            from => $dialect2, to => $dialect1, template => $input2,
        );
        is $d1_to_d1, $d2_to_d1,
            "equivalent transformation ($dialect1->$dialect1)==($dialect2->$dialect1) for $descr input";

        my $d2_to_d2 = $translator->translate(
            from => $dialect2, to => $dialect2, template => $input2,
        );
        my $d1_to_d2 = $translator->translate(
            from => $dialect1, to => $dialect2, template => $input1,
        );
        is $d2_to_d2, $d1_to_d2,
            "equivalent transformation ($dialect2->$dialect2)==($dialect1->$dialect2) for $descr input";
    }

    like exception { $translator->translate(
        from => 'JQueryTemplate', to => 'JQueryTemplate', template => undef,
    ); }, qr/cannot parse undef input/i, 'JQuery dies on undef input';

};


done_testing();


__DATA__
@@ jquery.txt
foo{{=bar}}<br><a href="pre{{=baz}}post">quux</a>
@@ native.json
[
 {"type" : "text", "value" : "foo"},
 {"type" : "variable", "name" : "bar"},
 {"type" : "newline"},
 {
   "type" : "link",
   "url"  : {
     "varstring_type"    : "variable",
     "text_segments"     : ["pre","post"],
     "variable_segments" : ["baz",""]
   },
   "label" : {
     "varstring_type"    : "static",
     "text_segments"     : ["quux"],
     "variable_segments" : [""]
   }
 }
]
