#!/usr/bin/env perl

# This file tests the API's response to bad parameters.  There are
# three possible responses: the update is accepted, the update is
# rejected, and the update is ignored.


use Clone qw(clone);
use Data::Section::Simple qw(get_data_section);
use MooX::Types::MooseLike::Base qw(ArrayRef HashRef);

use Test::Roo;
use lib 't/lib';
with 't::Role::Schema', 't::Role::Mech', 't::Role::WebApp', 't::Role::API',
    'Judoon::Role::JsonEncoder';

has param_debug => (is => 'rw', default => 0);

after setup => sub {
    my ($self) = @_;
    $self->load_fixtures(qw(init api));
};


# PUT  /user
# POST /user/datasets
# POST /user/pages
test '/user' => sub {
    my ($self) = @_;

    my $user_rs = $self->schema->resultset('User');
    my $me      = $user_rs->find({username => 'me'});

    # name             type        nullable serializable
    # id               integer     0        1
    # username         varchar(40) 0        1
    # password         text        0        0
    # password_expires timestamp   1        0
    # name             text        0        1
    # email_address    text        0        1
    # active           boolean     0        0
    $self->run_update_tests(
        '/api/user', $me, [
            # type      key                 newval
            [ 'ignore', 'id',               14,                 ],
            [ 'ignore', 'username',         'moo',              ],
            [ 'ignore', 'password',         'thunkabump',       ],
            [ 'ignore', 'password',         undef,              ],
            [ 'ignore', 'email_address',    '',                 ],
            [ 'ignore', 'active',           0,                  ],
            [ 'ignore', 'active',           'moo',              ],
            [ 'ignore', 'password_expires', DateTime->now . "", ],
            [ 'ignore', 'password_expires', 'moo',              ],

            [ 'fail',   'name',             undef,              ],

            [ 'pass',   'name',             'moo',              ],
            [ 'pass',   'name',             '',                 ],
        ],
    );

    subtest 'POST /user/datasets' => sub { fail 'not yet tested'; };
    subtest 'POST /user/pages' => sub { fail 'not yet tested'; };
};



# PUT    /datasets/$ds_id
# POST   /datasets/$ds_id/columns
# PUT    /datasets/$ds_id/columns/$dscol_id
test '/datasets' => sub {
    my ($self) = @_;

    my $user_rs = $self->schema->resultset('User');
    my $me      = $user_rs->find({username => 'me'});
    my $ds      = $me->datasets->first;
    my $ds_id   = $ds->id;
    my $ds_url  = "/api/datasets/$ds_id";

    subtest 'PUT /datasets/$ds_id' => sub {

        # dataset
        # name        type    null? fk? serial? numeric? default
        # id          integer 0     0   1       -        -
        # user_id     integer 0     1   1       -        -
        # name        text    0     0   1       -        -
        # description text    0     0   1       -        -
        # xxxoriginal    text    0     0   0       -        -
        # tablename   text    0     0   0       -        -
        # nbr_rows    integer 0     0   1       1        -
        # nbr_columns integer 0     0   1       1        -
        # permission  text    0     0   1       0        'private'
        $self->run_update_tests(
            $ds_url, $ds, [
                # expect    key            newval
                [ 'ignore', 'id',          14,    ],
                [ 'ignore', 'id',          undef, ],
                [ 'ignore', 'user_id',     14,    ],
                [ 'ignore', 'user_id',     undef, ],
                [ 'ignore', 'tablename',   'moo', ],
                [ 'ignore', 'tablename',   undef, ],
                [ 'ignore', 'nbr_rows',    20,    ],
                [ 'ignore', 'nbr_rows',    'moo', ],
                [ 'ignore', 'nbr_rows',    undef, ],
                [ 'ignore', 'nbr_columns', 20,    ],
                [ 'ignore', 'nbr_columns', 'moo', ],
                [ 'ignore', 'nbr_columns', undef, ],

                [ 'fail',   'name',        undef, ],
                [ 'fail',   'description', undef, ],
                [ 'fail',   'permission',  'moo', ],
                [ 'fail',   'permission',  '',    ],
                [ 'fail',   'permission',  undef, ],

                [ 'pass',   'name',        'moo',     ],
                [ 'pass',   'name',        '',        ],
                [ 'pass',   'description', 'moo',     ],
                [ 'pass',   'description', '',        ],
                [ 'pass',   'permission',  'private', ],
            ],
        );
    };

    subtest 'POST /datasets/$ds_id/columns' => sub { fail 'not yet tested'; };

    subtest 'PUT /datasets/$ds_id/columns/$dscol_id' => sub {

        my $dscol = $ds->ds_columns_ordered->first;
        my $dscol_url = "$ds_url/columns/" . $dscol->id;

        # dataset column
        # name       type    null? fk? serial? numeric? default
        # id         integer  0     0  1       1        -
        # dataset_id integer  0     1  1       1        -
        # name       text     0     0  1       0        -
        # shortname  text     1     0  1       0        -
        # sort       integer  0     0  1       1        -
        # data_type  text     0     1  1       0        -
        # -- JSON
        # data_type
        # sample_data
        $self->run_update_tests(
            $dscol_url, $dscol, [
                # expect    key            newval
                [ 'ignore', 'id',          14,    ],
                [ 'ignore', 'id',          undef, ],
                [ 'ignore', 'dataset_id',  14,    ],
                [ 'ignore', 'dataset_id',  undef, ],
                [ 'ignore', 'name',        'moo', ],
                [ 'ignore', 'name',        undef, ],
                [ 'ignore', 'shortname',   'moo', ],
                [ 'ignore', 'shortname',   undef, ],
                [ 'ignore', 'sort',        14,    ],
                [ 'ignore', 'sort',        undef, ],
                [ 'ignore', 'sample_data', 'moo', ],
                [ 'ignore', 'sample_data', undef, ],

                [ 'fail',   'data_type',   'moo', ],
                [ 'fail',   'data_type',   undef, ],

                [ 'pass',   'data_type',   'Biology_Accession_Entrez_GeneSymbol', ],
            ],
        );
    };
};



# PUT    /pages/$page_id
# POST   /pages/$page_id/columns
# PUT    /pages/$page_id/columns/$pagecol_id
test '/pages' => sub {
    my ($self) = @_;

    my $user_rs  = $self->schema->resultset('User');
    my $me       = $user_rs->find({username => 'me'});
    my $ds       = $me->datasets->first;
    my $ds_id    = $ds->id;
    my $ds_url   = "/api/datasets/$ds_id";
    my $page     = $ds->pages_ordered->first;
    my $page_id  = $page->id;
    my $page_url = "/api/pages/$page_id";

    subtest 'PUT /pages/$page_id' => sub {
        # page
        # name        type    null? fk? serial? numeric? default
        # id          integer 0     0   1       1        -
        # dataset_id  integer 0     1   1       1        -
        # title       text    0     0   1       0        -
        # preamble    text    0     0   1       0        -
        # postamble   text    0     0   1       0        -
        # permission  text    0     0   1       0        'private'
        # -- from JSON
        # nbr_rows
        # nbr_columns
        $self->run_update_tests(
            $page_url, $page, [
                [ 'ignore', 'id',          14,    ],
                [ 'ignore', 'id',          undef, ],
                [ 'ignore', 'dataset_id',  14,    ],
                [ 'ignore', 'dataset_id',  undef, ],
                [ 'ignore', 'nbr_rows',    20,    ],
                [ 'ignore', 'nbr_rows',    'moo', ],
                [ 'ignore', 'nbr_rows',    undef, ],
                [ 'ignore', 'nbr_columns', 20,    ],
                [ 'ignore', 'nbr_columns', 'moo', ],
                [ 'ignore', 'nbr_columns', undef, ],

                [ 'fail',   'title',       undef, ],
                [ 'fail',   'preamble',    undef, ],
                [ 'fail',   'postamble',   undef, ],
                [ 'fail',   'permission',  'moo', ],
                [ 'fail',   'permission',  '',    ],
                [ 'fail',   'permission',  undef, ],

                [ 'pass',   'title',       'moo',     ],
                [ 'pass',   'title',       '',        ],
                [ 'pass',   'preamble',    'moo',     ],
                [ 'pass',   'preamble',    '',        ],
                [ 'pass',   'postamble',   'moo',     ],
                [ 'pass',   'postamble',   '',        ],
                [ 'pass',   'permission',  'private', ],
                [ 'pass',   'permission',  'public',  ],
            ],
        );

    };


    subtest 'POST /pages/$page_id/columns' => sub { fail 'nyi' };


    subtest 'PUT /pages/$page_id/columns/$pagecol_id' => sub {

        my $pagecol     = $page->page_columns_ordered->first;
        my $pagecol_url = "$page_url/columns/" . $pagecol->id;

        # PAGE COLUMN
        # NAME        TYPE    NULL? FK? SERIAL? NUMERIC? DEFAULT
        # id          integer 0     0   1       1        -
        # page_id     integer 0     1   1       1        -
        # title       text    0     0   1       0        -
        # template    text    0     0   0       0        -
        # sort        integer 0     0   1       1        -
        # --- JSON
        # template
        # widgets

        $self->run_update_tests(
            $pagecol_url, $pagecol, [
                # expect    key            newval
                [ 'ignore', 'id',          14,    ],
                [ 'ignore', 'id',          undef, ],
                [ 'ignore', 'page_id',     14,    ],
                [ 'ignore', 'page_id',     undef, ],
                [ 'ignore', 'sort',        14,    ],
                [ 'ignore', 'template',    'moo', ],
                [ 'ignore', 'template',    undef, ],

                [ 'fail',  'title',   undef, ],
                [ 'fail',  'sort',    undef, ],
                [ 'fail',  'sort',    'moo', ],
                [ 'fail',  'widgets', '',    ],

                [ 'pass',   'title',    'moo', ],
                [ 'pass',   'title',    '',    ],
                [ 'pass',   'sort',     10,    ],
                [ 'pass',   'sort',     -1,    1, ],

                [ 'pass',   'widgets', [],    ],

            ],
        );

    };
};


# POST /template
test '/services' => sub {
    my ($self) = @_;

    subtest 'POST /template' => sub {

        # valid:
        #   template
        #   widgets
        # errors:
        #   tmpl_p tmpl_v widgets_p widgets_v r
        #   0      0      0         0         \422
        #   0      0      0         1         na
        #   0      0      1         0         \422
        #   0      0      1         1         \200 {template}
        #   0      1      0         0         na
        #   0      1      0         1         na
        #   0      1      1         0         na
        #   0      1      1         1         na
        #   1      0      0         0         \422
        #   1      0      0         1         na
        #   1      0      1         0         \422
        #   1      0      1         1         \422
        #   1      1      0         0         \200 widgets
        #   1      1      0         1         na
        #   1      1      1         0         \422
        #   1      1      1         1         \422

        my $good_tmpl = get_data_section('js_template');
        chomp $good_tmpl;
        my $bad_tmpl  = '<a href="foo"><p>thing</p></a>';

        my $good_widgets = $self->decode_json( get_data_section('serialized') );
        my $bad_widgets  = [{type => 'mpp'}];

        my @tests_fail = (
            [{                                                  } ],
            [{                        widgets => $bad_widgets,  } ],
            [{template => $bad_tmpl,                            } ],
            [{template => $bad_tmpl,  widgets => $bad_widgets,  } ],
            [{template => $bad_tmpl,  widgets => $good_widgets, } ],
            [{template => $good_tmpl, widgets => $bad_widgets,  } ],
            [{template => $good_tmpl, widgets => $good_widgets, } ],
        );
        for my $test (@tests_fail) {
            my ($payload) = @$test;
            $self->add_route_test('/api/template', 'me', 'POST', $payload, \422);
        }


        my @tests_ok = (
            [{widgets  => $good_widgets,}, {template => $good_tmpl},    ],
            [{template => $good_tmpl,   }, {widgets  => $good_widgets}, ],
        );
        for my $test (@tests_ok) {
            my ($payload, $expect) = @$test;
            $self->add_route_test(
                '/api/template', 'me', 'POST', $payload,
                { want => $expect }
            );
        }
    };
};


run_me();
done_testing();


sub run_update_tests {
    my ($self, $url, $obj, $tests) = @_;
    for my $test (@$tests) {
        my ($type, $key, $val, $expval) = @$test;
        $self->_test_update($type, $url, 'me', $obj, $key, $val, $expval);
        $self->reset_fixtures();
        $self->load_fixtures(qw(init api));
    }
}

sub _test_update {
    my ($self, $type, $route, $userspec, $orig_obj, $key, $val, $expval) = @_;
    diag "$type: $userspec PUT $route \{" . $key . ' ==> ' . _stringy_val($val)
        . (defined($expval) ? ' ==> ' . _stringy_val($expval) : '') . '}'
        if ($self->param_debug);

    my ($status, $expect) = $type eq 'pass'   ? (\204, {$key => $expval // $val})
                          : $type eq 'fail'   ? (\422, {})
                          : $type eq 'ignore' ? (\204, {})
                          :      die "Invalid type ($type) in _test_update";

    my $upd_obj      = $orig_obj->TO_JSON;
    $upd_obj->{$key} = $val;
    $self->add_route_test($route, $userspec, 'PUT', $upd_obj, $status);
    $self->add_route_get_like($route, $userspec, $orig_obj, $expect);
}
sub add_route_get_like {
    my ($self, $route, $userspec, $orig_obj, $updates) = @_;
    $self->add_route_test(
        $route, $userspec, 'GET', {}, { want => {
            %{$orig_obj->discard_changes->TO_JSON}, %$updates
        }}
    );
}

sub _stringy_val { return !defined($_[0]) ? '*undef*' : ($_[0] eq '') ? q{''} : $_[0]; }




__DATA__
@@ js_template
<strong><em>foo</em></strong><strong>{{bar}}</strong><br><em><a href="pre{{baz}}post">quux</a></em>
@@ serialized
[
 {"type" : "text", "value" : "foo", "formatting" : ["italic", "bold"]},
 {"type" : "variable", "name" : "bar", "formatting" : ["bold"]},
 {"type" : "newline", "formatting" : []},
 {
   "type" : "link",
   "url"  : {
     "varstring_type"    : "variable",
     "type"              : "varstring",
     "accession"         : "",
     "text_segments"     : ["pre","post"],
     "variable_segments" : ["baz",""],
     "formatting"        : []
   },
   "label" : {
     "varstring_type"    : "static",
     "type"              : "varstring",
     "accession"         : "",
     "text_segments"     : ["quux"],
     "variable_segments" : [""],
     "formatting"        : []
   },
  "formatting" : ["italic"]
 }
]
