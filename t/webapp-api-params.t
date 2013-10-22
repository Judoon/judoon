#!/usr/bin/env perl

# This file tests the API's response to bad parameters.  There are
# three possible responses: the update is accepted, the update is
# rejected, and the update is ignored.


use Clone qw(clone);
use MooX::Types::MooseLike::Base qw(ArrayRef HashRef);

use Test::Roo;
use lib 't/lib';
with 't::Role::Schema', 't::Role::Mech', 't::Role::WebApp', 't::Role::API',
    'Judoon::Role::JsonEncoder', 't::Role::TmplFixtures';

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

    subtest 'PUT /user' => sub {

        # User
        # NAME             TYPE        NULL? SERIAL? NUMERIC?
        # --------------------------------------------------
        # id               integer     0     1       1
        # username         varchar(40) 0     1       0
        # password         text        0     0       0
        # password_expires timestamp   1     0       0
        # name             text        0     1       0
        # email_address    text        0     1       0
        # active           boolean     0     0       0
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
    };


    subtest 'POST /user/datasets' => sub {
      TODO: {
            local $TODO = 'Dataset upload not yet implemented';
            fail('not yet implemented');
        }
    };


    subtest 'POST /user/pages' => sub {

        # Pages
        # valid params:
        #   dataset_id: $num
        #   type:       (clone, basic, blank)
        #   clone_from: when $type=clone
        # ignore params: use defaults
        #   title / preamble / postamble / permission / id
        # when (type = blank | basic)
        #    title/preamble/postamble/permission = defaults
        # when (type = clone)
        #  clone_from = $page_id
        # errors:
        #   if dataset_id->is_not_owned by user => Forbidden
        #   if type = undef                     => ok, assume 'blank'
        #   if type != any(clone, basic, blank) => 422?
        #   if type = blank:                    => ok, has sensible defaults
        #   if type = basic:                    => ok, has sensible defaults
        #   if type = clone:
        #    if !clone_from or clone_from != \d+     => 422
        #    if user->not_owned(clone_from)          => Forbidden
        #    if clone->ds_columns != our->ds_columns => ???
        #    else                                    => ok


        my $my_ds         = $me->datasets->first;
        my $my_ds_id      = $my_ds->id;
        my $my_clone_page = $my_ds->pages->first;
        my $my_clone_id   = $my_clone_page->id;
        my $my_mismatched_clone = ($me->datasets->all)[-1]->pages->first->id;

        my $you           = $user_rs->find({username => 'you'});
        my $your_ds       = $you->datasets->first;
        my $your_ds_id    = $your_ds->id;
        my $your_clone_id = $your_ds->pages->first->id;

        my $blank_page = {
            title      => q{New Blank Page},
            preamble   => '',
            postamble  => '',
            permission => 'private',
            dataset_id => $my_ds_id,
        };
        my $basic_page = {
            title      => $my_ds->name,
            permission => 'private',
            dataset_id => $my_ds_id,
        };
        my $clone_page = {
            title      => $my_clone_page->title,
            preamble   => $my_clone_page->preamble,
            postamble  => $my_clone_page->postamble,
            permission => 'private',
            dataset_id => $my_ds_id,
        };

        my @tests_ok = (
            [{                }, $blank_page, ],
            [{type => 'blank',}, $blank_page, ],
            [{type => 'basic',}, $basic_page, ],
            [{type => 'clone', clone_from => $my_clone_id,}, $clone_page],
        );
        for my $test (@tests_ok) {
            my ($new_page, $compare_obj) = @$test;
            $new_page->{dataset_id} = $my_ds_id;
            $self->add_route_created(
                '/api/user/pages', 'me', 'POST', $new_page, $compare_obj,
            );
        }

        my @tests_fail = (
            [{type => 'blank', dataset_id => $your_ds_id,          }, \404, ],
            [{type => 'moo',                                       }, \422, ],
            [{type => 'clone',                                     }, \422, ],
            [{type => 'clone', clone_from => 'moo',                }, \422, ],
            [{type => 'clone', clone_from => $your_clone_id,       }, \422, ],
            [{type => 'clone', clone_from => $my_mismatched_clone, }, \422, ],
        );
        for my $test (@tests_fail) {
            my ($new_page, $error_code) = @$test;
            $new_page->{dataset_id} //= $my_ds_id;
            $self->add_route_test(
                '/api/user/pages', 'me', 'POST', $new_page, $error_code
            );
        }
    };
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

    subtest 'POST /datasets/$ds_id/columns' => sub {

        # DatasetColumns
        # valid params:
        #  dataset_id: ignore or error if it doesn't agree w/ $ds_id in url
        #  that_table_id: 
        #  new_col_name: 
        #  rest of data gets passed to build_actor();

      TODO: {
            local $TODO = "not yet implemented";
            fail 'not yet tested';
        }
    };

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


    subtest 'POST /pages/$page_id/columns' => sub {

        # PageColumns
        # valid params:
        #   template: must be translated
        #   widgets:  nyi
        #   title:    text
        # ignore params:
        #   sort:    default to end, to update, PUT all?
        #   page_id: get from url
        #   id:      ignore
        # when ()
        # errors:
        #   if {title, sort} exists but not defined


        my $pagecols_url = "${page_url}/columns";
        my ($good_tmpl, $good_widgets)
            = @{ $self->get_tmpl_fixture('basic_equiv') }{ qw(jstmpl widgets) };
        my $basic_pagecol = {
            page_id  => $page_id,
            template => $good_tmpl,
            widgets  => $good_widgets,
        };
        my $pagecol_count = $page->page_columns_rs->count + 1;

        my @tests_ok = (
            [{title => 'hello', template => $good_tmpl,   }, ],
            [{title => 'hello', widgets  => $good_widgets,}, ],
            [{title => '',      template => $good_tmpl,   }, ],
        );
        for my $test (@tests_ok) {
            my ($new_pagecol) = @$test;
            my $compare_obj = {
                %$basic_pagecol, title => $new_pagecol->{title},
                sort => $pagecol_count++,
            };
            $self->add_route_created(
                $pagecols_url, 'me', 'POST', $new_pagecol, $compare_obj,
            );
        }
        $self->reset_fixtures();
        $self->load_fixtures(qw(init api));

        # hack: Create dummay pagecol, guess next id and sort by adding one
        my $dummy_pagecol = $page->create_related(
            'page_columns', {title => 'hello', template => $good_tmpl}
        );
        my $pagecol_id = $dummy_pagecol->id + 1;
        $pagecol_count = $dummy_pagecol->sort + 1;
        my @tests_ignore = (
            [{sort    => 1,    }],
            [{sort    => undef,}],
            [{sort    => 'moo',}],
            [{id      => 1,    }],
            [{id      => undef,}],
            [{id      => 'moo',}],
            [{page_id => 1,    }],
            [{page_id => undef,}],
            [{page_id => 'moo',}],
        );
        for my $test (@tests_ignore) {
            my ($new_page) = @$test;

            my $new_pagecol = {
                title => 'hello', template => $good_tmpl, %$new_page,
            };
            my $compare_obj = {
                %$basic_pagecol, title => 'hello', sort => $pagecol_count++,
                id => $pagecol_id++,
            };

            $self->add_route_created(
                $pagecols_url, 'me', 'POST', $new_pagecol, $compare_obj,
            );
        }

        my ($bad_tmpl, $bad_widgets)
            = @{ $self->get_tmpl_fixture('invalid') }{ qw(jstmpl widgets) };
        my @tests_fail = (
            [{title => undef}, \422],
            [{sort  => undef}, \422],
            [{sort  => 'moo'}, \422],
            [{template => $bad_tmpl}, \422],
            [{widgets => $bad_widgets}, \422],
            [{widgets => $bad_widgets}, \422],
            [{template => $good_tmpl, widgets => $good_widgets}, \422],
        );
        for my $test (@tests_fail) {
            my ($new_page, $error_code) = @$test;
            $self->add_route_test(
                $pagecols_url, 'me', 'POST', $new_page, $error_code
            );
        }
    };


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

        my ($good_tmpl, $good_widgets)
            = @{ $self->get_tmpl_fixture('basic_equiv') }{ qw(jstmpl widgets) };
        my ($bad_tmpl, $bad_widgets)
            = @{ $self->get_tmpl_fixture('invalid') }{ qw(jstmpl widgets) };

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

