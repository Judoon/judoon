#!/usr/bin/env perl

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

    my $me_json = $me->TO_JSON;
    my @user_tests_fail = (
        # key                 newval
        [ 'id',               14,                 ],
        [ 'username',         'moo',              ],
        [ 'password',         'thunkabump',       ],
        [ 'password',         undef,              ],
        [ 'email_address',    '',                 ],
        [ 'active',           0,                  ],
        [ 'active',           'moo',              ],
        [ 'password_expires', DateTime->now . "", ],
        [ 'password_expires', 'moo',              ],
        [ 'name',             undef,              ],
    );
    for my $test (@user_tests_fail) {
        $self->update_fails_ok('/api/user', 'me', $me, @$test);
    }

    my @user_tests_ok = (
        [ 'name', 'moo', ],
        [ 'name', '',    ],
    );
    for my $test (@user_tests_ok) {
        $self->update_ok('/api/user', 'me', $me, @$test);
        $self->reset_fixtures();
        $self->load_fixtures(qw(init api));
    }

    diag('??? POST /user/datasets');
    diag('??? POST /user/pages');
};



# PUT    /datasets/$ds_id
# DELETE /datasets/$ds_id
# POST   /datasets/$ds_id/columns
# PUT    /datasets/$ds_id/columns/$dscol_id
test '/datasets' => sub {
    my ($self) = @_;

    my $user_rs = $self->schema->resultset('User');
    my $me      = $user_rs->find({username => 'me'});
    my $ds      = $me->datasets->first;
    my $ds_id   = $ds->id;
    my $ds_url  = "/api/datasets/$ds_id";

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

    my @ds_tests_fail = (
        # key            newval
        [ 'id',          14,    ],
        [ 'id',          undef, ],
        [ 'user_id',     14,    ],
        [ 'user_id',     undef, ],
        [ 'description', undef, ],
        [ 'tablename',   'moo', ],
        [ 'tablename',   undef, ],
        [ 'nbr_rows',    20,    ],
        [ 'nbr_rows',    'moo', ],
        [ 'nbr_rows',    undef, ],
        [ 'nbr_columns', 20,    ],
        [ 'nbr_columns', 'moo', ],
        [ 'nbr_columns', undef, ],
        [ 'permission',  'moo', ],
        [ 'permission',  '',    ],
        [ 'permission',  undef, ],
    );
    for my $test (@ds_tests_fail) {
        $self->update_fails_ok($ds_url, 'me', $ds, @$test);
    }

    my @ds_tests_ok = (
        [ 'name',        'moo',     ],
        [ 'name',        '',        ],
        [ 'description', 'moo',     ],
        [ 'description', '',        ],
        [ 'permission',  'private', ],
    );
    for my $test (@ds_tests_ok) {
        $self->update_ok($ds_url, 'me', $ds, @$test);
        $self->reset_fixtures();
        $self->load_fixtures(qw(init api));
    }



    # dataset column
    # name       type    null? fk? serial? numeric? default
    # id         integer  0     0  1       1        -
    # dataset_id integer  0     1  1       1        -
    # name       text     0     0  1       0        -
    # shortname  text     1     0  1       0        -
    # sort       integer  0     0  1       1        -
    # data_type  text     0     1  1       0        -


    diag('??? PUT    /datasets/$ds_id');
    diag('??? DELETE /datasets/$ds_id');
    diag('??? POST   /datasets/$ds_id/columns');
    diag('??? PUT    /datasets/$ds_id/columns/$dscol_id');
    pass('fake');
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


    diag('??? PUT    /pages/$page_id');
    diag('??? DELETE /pages/$page_id');
    diag('??? POST   /pages/$page_id/columns');
    diag('??? DELETE /pages/$page_id/columns');
    diag('??? PUT    /pages/$page_id/columns/$dscol_id');
    diag('??? DELETE /pages/$page_id/columns/$dscol_id');
    pass('fake');
};


# POST /template
test '/services' => sub {
    my ($self) = @_;

    diag('??? /template');
    pass('fake');
};


run_me();
done_testing();



sub update_fails_ok { shift->_test_update('fail', @_); }
sub update_ok       { shift->_test_update('pass', @_); }
sub _test_update {
    my ($self, $type, $route, $userspec, $orig_obj, $key, $val) = @_;
    diag "$type: $userspec PUT $route \{" . $key . ' ==> ' . _stringy_val($val) . '}'
        if ($self->param_debug);

    my ($status, $expect) = $type eq 'pass' ? (\204, {$key => $val})
                          : $type eq 'fail' ? (\422, {})
                          :      die "Invalid type ($type) in _test_update";

    my $obj_json = $orig_obj->TO_JSON;
    my $upd_obj = clone($obj_json);
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
