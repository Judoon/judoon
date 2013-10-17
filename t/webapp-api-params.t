#!/usr/bin/env perl

# This file tests the API's response to bad parameters.  There are
# three possible responses: the update is accepted, the update is
# rejected, and the update is ignored.


use Clone qw(clone);
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

    my @user_tests = (
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
    );
    for my $test (@user_tests) {
        my ($type, $key, $val) = @$test;
        $self->_test_update($type, '/api/user', 'me', $me, $key, $val);
        $self->reset_fixtures();
        $self->load_fixtures(qw(init api));
    }

    subtest 'POST /user/datasets' => sub { fail 'not yet tested'; };
    subtest 'POST /user/pages' => sub { fail 'not yet tested'; };
};



# PUT    /datasets/$ds_id
# DELETE /datasets/$ds_id <protected by access control>
# POST   /datasets/$ds_id/columns
# PUT    /datasets/$ds_id/columns/$dscol_id
test '/datasets' => sub {
    my ($self) = @_;

    my $user_rs = $self->schema->resultset('User');
    my $me      = $user_rs->find({username => 'me'});
    my $ds      = $me->datasets->first;
    my $ds_id   = $ds->id;
    my $ds_url  = "/api/datasets/$ds_id";

    $self->add_route_not_found('/api/datasets/moo', '*', 'GET', {});

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

        my @ds_tests = (
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
        );
        for my $test (@ds_tests) {
            my ($type, $key, $val) = @$test;
            $self->_test_update($type, $ds_url, 'me', $ds, $key, $val);
            $self->reset_fixtures();
            $self->load_fixtures(qw(init api));
        }
    };

    subtest 'DELETE /datasets/$ds_id' => sub { pass 'tested in webapp-api.t' };

    subtest 'POST /datasets/$ds_id/columns' => sub { fail 'not yet tested'; };
    subtest 'PUT /datasets/$ds_id/columns/$dscol_id' => sub {

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

        my $dscol = $ds->ds_columns_ordered->first;
        my $dscol_url = "$ds_url/columns/" . $dscol->id;


        my @dscol_tests = (
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
        );
        for my $test (@dscol_tests) {
            my ($type, $key, $val) = @$test;
            $self->_test_update($type, $dscol_url, 'me', $dscol, $key, $val);
            $self->reset_fixtures();
            $self->load_fixtures(qw(init api));
        }
    };


};



# PUT    /pages/$page_id
# DELETE /pages/$page_id
# POST   /pages/$page_id/columns
# DELETE /pages/$page_id/columns
# PUT    /pages/$page_id/columns/$pagecol_id
# DELETE /pages/$page_id/columns/$pagecol_id
test '/pages' => sub {
    my ($self) = @_;

    # page
    # name        type    null? fk? serial? numeric? default
    # id          integer 0     0   1       1        -
    # dataset_id  integer 0     1   1       1        -
    # title       text    0     0   1       0        -
    # preamble    text    0     0   1       0        -
    # postamble   text    0     0   1       0        -
    # permission  text    0     0   1       0        'private'

    # page column
    # name        type    null? fk? serial? numeric? default
    # id          integer 0
    # page_id     integer 0     1
    # title       text    0     0   1
    # template    text    0     0   0
    # sort        integer 0     0


    subtest 'PUT    /pages/$page_id' => sub { fail 'nyi' };
    subtest 'DELETE /pages/$page_id' => sub { fail 'nyi' };
    subtest 'POST   /pages/$page_id/columns' => sub { fail 'nyi' };
    subtest 'DELETE /pages/$page_id/columns' => sub { fail 'nyi' };
    subtest 'PUT    /pages/$page_id/columns/$dscol_id' => sub { fail 'nyi' };
    subtest 'DELETE /pages/$page_id/columns/$dscol_id' => sub { fail 'nyi' };
};


# POST /template
test '/services' => sub {
    my ($self) = @_;

    subtest 'POST /template' => sub { fail 'nyi'; };
};


run_me();
done_testing();



sub _test_update {
    my ($self, $type, $route, $userspec, $orig_obj, $key, $val) = @_;
    diag "$type: $userspec PUT $route \{" . $key . ' ==> ' . _stringy_val($val) . '}'
        if ($self->param_debug);

    my ($status, $expect) = $type eq 'pass'   ? (\204, {$key => $val})
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
