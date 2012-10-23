#/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Data::Section::Simple qw(get_data_section);
use Judoon::Tmpl::Factory;
use Judoon::Tmpl::Util;

subtest 'input validation' => sub {
    like exception {
        to_objects(from => 'BadDialect', template => '');
    }, qr{is not a valid dialect}i, 'dies w/ bad dialect to to_objects()';
    like exception {
        from_objects(to => 'BadDialect', objects => []);
    }, qr{is not a valid dialect}i, 'dies w/ bad dialect to from_objects()';
    like exception {
        translate(from => 'JQueryTemplate', to => 'BadDialect', template => 'foo{{=bar}}');
    }, qr{is not a valid dialect}i, 'dies w/ bad dialect for to in translate()';
    like exception {
        translate(from => 'BadDialect', to => 'Native', template => '');
    }, qr{is not a valid dialect}i, 'dies w/ bad dialect for from in translate()';

};

# Here are some tests for error-checking provided by Params::Validate
# and Method::Signatures. M::S tests' cover this, but Devel::Cover
# can't detect that.  We test it here to get that lovely, lovely field
# of green in our coverage report.
subtest 'Making Devel::Cover happy' => sub {

    # set up our error regexes
    my $pv_missing_arg   = qr{mandatory parameters? .* missing in call to}i;
    my $pv_wrong_arg     = qr{following parameter was passed .* but was not listed in the validation options}i;
    my $ms_missing_arg   = qr{In call to .* missing required argument}i;
    my $ms_too_many_args = qr{too many argument}i;
    my %descrs = (
        $ms_missing_arg => 'missing arg', $pv_wrong_arg => 'wrong arg',
        $ms_too_many_args => 'too many args', $pv_missing_arg => 'missing arg',
    );

    # failing inputs to Util::{translate,from_objects,to_objects}
    my @fails = (
        ['translate', [qw(from to)],                $pv_missing_arg,   ],
        ['translate', [qw(to template)],            $pv_missing_arg,   ],
        ['translate', [qw(from template)],          $pv_missing_arg,   ],
        ['translate', [qw()],                       $pv_missing_arg,   ],
        ['translate', [qw(from to template bogus)], $pv_wrong_arg,     ],

        ['from_objects', [qw()],                 $pv_missing_arg,    ],
        ['from_objects', [qw(to)],               $pv_missing_arg,    ],
        ['from_objects', [qw(objects)],          $pv_missing_arg,    ],
        ['from_objects', [qw(to objects bogus)], $pv_wrong_arg,      ],

        ['to_objects', [qw()],                    $pv_missing_arg,    ],
        ['to_objects', [qw(from)],                $pv_missing_arg,    ],
        ['to_objects', [qw(template)],            $pv_missing_arg,    ],
        ['to_objects', [qw(from template bogus)], $pv_wrong_arg,      ],
    );
    my %fail_args = (
        from => 'Native', to => 'Native', template => '', objects => [],
        bogus => '',
    );
    for my $failset (@fails) {
        my ($method, $argset, $error) = @$failset;
        like exception {
            no strict 'refs';
            $method->(map {$_ => $fail_args{$_}} @$argset);
        }, $error, "calling $method w/ $descrs{$error}";
    }


    # failing inputs to Dialect::*::{parse,produce}
    for my $dialect (dialects()) {
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

    for my $dialect (dialects()) {
        ok my $tmpl = from_objects(
            to => $dialect, objects => \@test_objects
        ), "$dialect can build a template from objects";
        ok my @back_objects = to_objects(
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

        my $d1_to_d1 = translate(
            from => $dialect1, to => $dialect1, template => $input1,
        );
        my $d2_to_d1 = translate(
            from => $dialect2, to => $dialect1, template => $input2,
        );
        is $d1_to_d1, $d2_to_d1,
            "equivalent transformation ($dialect1->$dialect1)==($dialect2->$dialect1) for $descr input";

        my $d2_to_d2 = translate(
            from => $dialect2, to => $dialect2, template => $input2,
        );
        my $d1_to_d2 = translate(
            from => $dialect1, to => $dialect2, template => $input1,
        );
        is $d2_to_d2, $d1_to_d2,
            "equivalent transformation ($dialect2->$dialect2)==($dialect1->$dialect2) for $descr input";

        # convenience methods
        chomp $input1;
        my $input1_redux = nodes_to_jstmpl(
            native_to_nodes( nodes_to_native( jstmpl_to_nodes($input1) ) )
        );
        is $input1_redux, $input1, 'jstmpl passed through convenience functions stays the same';
    }


    like exception { translate(
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
