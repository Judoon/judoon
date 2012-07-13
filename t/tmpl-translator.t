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
                text_segments     => ['foo','bar',],
                variable_segments => ['baz',],
            },
            label => {
                varstring_type    => 'static',
                text_segments     => ['foo','bar',],
                variable_segments => ['baz',],
            },
        }),
    );

    for my $dialect ($translator->dialects()) {
        next if ($dialect eq 'JQueryTemplate'); # no parse for JQueryTemplate yet.
        ok my $tmpl = $translator->from_objects(
            to => $dialect, objects => \@test_objects
        ), "$dialect can build a template from objects";
        ok my @back_objects = $translator->to_objects(
            from => $dialect, template => $tmpl,
        ), "dialect can build objects from a template";
        is_deeply \@back_objects, \@test_objects,
            '  ...and the object set is the same';
    }


    my $webwidget_tmpl = get_data_section('webwidgets.html');
    my $native_tmpl    = get_data_section('native.json');

    my $native_1 = $translator->translate(
        from => 'WebWidgets', to => 'Native',
        template => $webwidget_tmpl,
    );
    my $jq_tmpl_1 = $translator->translate(
        from => 'WebWidgets', to => 'JQueryTemplate',
        template => $webwidget_tmpl,
    );
    my $jq_tmpl_2 = $translator->translate(
        from => 'Native', to => 'JQueryTemplate',
        template => $native_1,
    );

    is $jq_tmpl_1, $jq_tmpl_2, 'equivalent transformation';
};



# diag "Native: $native_1";
# diag "";
# diag "JQueryTemplate1 is: $jq_tmpl_1";
# diag "";
# diag "JQueryTemplate2 is: $jq_tmpl_2";


# my @dialects = qw(Native WebWidgets JQueryTemplate);
# my @test_types = qw(
#     text_only data_only url_only newline_only
#     combined
# );
# 
# my %templates;
# for my $dialect (@dialects) {
#     for my $test_type (@test_types) {
#         $templates{$dialect}->{$test_type}
#             = get_data_section( lc($dialect) . '-' . $test_type )
#                 or die "Unable to find test template for $dialect / $test_type";
#     }
# }
# 
# 
# my @comparisons = map {my $orig = $_; map {[$orig, $_]} @dialects;} @dialects;
# for my $comparison (@comparisons) {
#     my ($from_dialect, $to_dialect) = @_;
# 
#     subtest "Translating $from_dialect => $to_dialect" => sub {
#         for my $test (@test_types) {
#             my $output = $translator->translate({
#                 from     => $from_dialect,
#                 to       => $to_dialect,
#                 template => $templates{$from_dialect}->{$test},
#             });
#             is $output, $templates{$to_dialect}{$test}, "translated $test ok";
#         }
#     };
# }




done_testing();


__DATA__
@@ webwidgets.html
       <div id="widget_id_0" class="widget-object widget-type-text widget-inline btn-group">
        <input id="widget_format_id_0" class="inner-small span2 w-dropdown widget-format-target widget-formatting-bold" placeholder="Type text here" value="Text" type="text"><a class="add-to btn dropdown-toggle" data-toggle="dropdown" href="#">
          <i class="icon-cog"></i>
        </a>
        <ul class="dropdown-menu">
          <li><a class="widget-action-bold"><i class="icon-bold"></i>Bold</a></li>
          <li><a class="widget-action-italic"><i class="icon-italic"></i>Italicize</a></li>
          <li><a class="widget-action-delete"><i class="icon-trash"></i>Delete</a></li>
        </ul>
      </div>

      <div id="widget_id_1" class="widget-object widget-type-data widget-inline btn-group">
        <select id="widget_format_id_1" class="w-dropdown widget-format-target">
          
          <option value="gene_symbol">{Gene Symbol}</option>
          
          <option value="protein_name" selected="selected">{Protein Name}</option>
          
          <option value="flybase_link">{Flybase Link}</option>
          
          <option value="fold_change">{Fold Change}</option>
          
          <option value="proposed_function">{Proposed Function}</option>
          
          <option value="nearest_mammalian_homolog">{Nearest mammalian homolog}</option>
          
          <option value="unigene__human_homolog_">{Unigene (human homolog)}</option>
          
        </select><a class="add-to btn dropdown-toggle" data-toggle="dropdown" href="#">
          <i class="icon-cog"></i>
        </a>
        <ul class="dropdown-menu">
          <li><a class="widget-action-bold"><i class="icon-bold"></i>Bold</a></li>
          <li><a class="widget-action-italic"><i class="icon-italic"></i>Italicize</a></li>
          <li><a class="widget-action-delete"><i class="icon-trash"></i>Delete</a></li>
        </ul>
      </div>

      <div id="widget_id_2" class="widget-object widget-type-newline-icon"><i class="icon-arrow-down"></i></div>

      <div id="widget_id_3" class="widget-object widget-type-newline"></div>

      <div id="widget_id_4" class="widget-object widget-type-text widget-inline btn-group">
        <input id="widget_format_id_4" class="inner-small span2 w-dropdown widget-format-target widget-formatting-italic" placeholder="Type text here" value="Link" type="text"><a class="add-to btn dropdown-toggle" data-toggle="dropdown" href="#">
          <i class="icon-cog"></i>
        </a>
        <ul class="dropdown-menu">
          <li><a class="widget-action-bold"><i class="icon-bold"></i>Bold</a></li>
          <li><a class="widget-action-italic"><i class="icon-italic"></i>Italicize</a></li>
          <li><a class="widget-action-delete"><i class="icon-trash"></i>Delete</a></li>
        </ul>
      </div>

      <div id="widget_id_5" class="widget-object widget-type-link widget-inline btn-group">
        <a class="btn btn-edit-link"><i class="icon-pencil"></i> Edit link</a><a class="add-to btn dropdown-toggle" data-toggle="dropdown" href="#">
          <i class="icon-cog"></i>
        </a>
        <ul class="dropdown-menu">
          <li><a class="widget-action-bold"><i class="icon-bold"></i>Bold</a></li>
          <li><a class="widget-action-italic"><i class="icon-italic"></i>Italicize</a></li>
          <li><a class="widget-action-delete"><i class="icon-trash"></i>Delete</a></li>
        </ul>
        <input id="widget_format_id_5" class="widget-link-url-source widget-format-target" value="" type="hidden">
        <input class="widget-link-url-type" value="accession" type="hidden">
        <input class="widget-link-url-accession" value="" type="hidden">
        <input class="widget-link-url-text-segment-1" value="http://www.ncbi.nlm.nih.gov/gene/" type="hidden">
        <input class="widget-link-url-text-segment-2" value="" type="hidden">
        <input class="widget-link-url-variable-segment-1" value="protein_name" type="hidden">

        <input class="widget-link-label-type" value="static" type="hidden">
        <input class="widget-link-label-accession" value="" type="hidden">
        <input class="widget-link-label-text-segment-1" value="Entrez" type="hidden">
        <input class="widget-link-label-text-segment-2" value="" type="hidden">
        <input class="widget-link-label-variable-segment-1" value="" type="hidden">
      </div>

      <div id="canvas_cursor"></div>
@@ native.json
    {
        'type'  : 'text',
        'value' : 'foo'
}
