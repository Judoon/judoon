#!/usr/bin/env perl

use MooX::Types::MooseLike::Base qw(ArrayRef HashRef);

use Test::Roo;
use v5.16;

use lib 't/lib';

with 't::Role::Schema', 't::Role::Mech', 't::Role::WebApp',
    'Judoon::Role::JsonEncoder';

use Clone qw(clone);
use HTTP::Request::Common qw(GET POST PUT DELETE);
use List::MoreUtils ();
use Test::JSON;
use Text::Table;

has routes   => (is => 'lazy', isa => ArrayRef,);
has my_users => (is => 'lazy', isa => ArrayRef,);
has methods  => (is => 'lazy', isa => ArrayRef,);
has _tests   => (is => 'lazy', isa => HashRef,);
has debug    => (is => 'rw', default => 0,);


my %users = (
    me  => {
        username => 'me', password => 'mypassword',
        name => 'Me Who I Am', email_address => 'me@example.com',
    },
    you => {
        username => 'you', password => 'yourpassword',
        name => 'You Who You Are', email_address => 'you@example.com',
    },
);

after setup => sub {
    my ($self) = @_;
    $self->load_fixtures('init');

    $self->add_fixture(
        'api' => sub {
            my ($self) = @_;
            my $user_rs = $self->schema()->resultset('User');

            # build fixtures for me user
            my %me = (object => $user_rs->create_user($users{me}));
            my $my_pub_ds
                = $me{object}->import_data_by_filename('t/etc/data/api/me-public.xls')
                    ->update({permission => 'public'});
            my $my_priv_ds
                = $me{object}->import_data_by_filename('t/etc/data/api/me-private.xls');
            $me{public_ds} = {
                object       => $my_pub_ds,
                public_page  => $my_pub_ds->create_basic_page->update({permission => 'public'}),
                private_page => $my_pub_ds->create_basic_page,
            };
            $me{private_ds} = {
                object       => $my_priv_ds,
                public_page  => $my_priv_ds->create_basic_page->update({permission => 'public'}),
                private_page => $my_priv_ds->create_basic_page,
            };

            # build fixtures for you user
            my %you = (object => $user_rs->create_user($users{you}));
            my $you_pub_ds
                = $you{object}->import_data_by_filename('t/etc/data/api/you-public.xls')
                    ->update({permission => 'public'});
            $you{public_ds} = {
                object      => $you_pub_ds,
                public_page => $you_pub_ds->create_basic_page->update({permission => 'public'}),
            };

        }
    );

    $self->load_fixtures('api');
};


test 'Basic Tests' => sub {
    my ($self) = @_;

    for my $uri (qw(/api /api/)) {
        $self->mech->get_ok($uri, "get $uri");
        is $self->mech->uri, 'http://localhost/', '  ...redirects to root';
    }

    # this should eventually go away, be replaced by /datasets/1/data
    $self->mech->get_ok('/api/datasetdata', 'get /api/datasetdata');
};


# READONLY ROUTES

# A read-only route for getting information about all / other users
test '/users' => sub {
    my ($self) = @_;

    my $user_rs     = $self->schema->resultset('User');
    my @all_users   = map {$_->TO_JSON} $user_rs->all;
    my $me          = $user_rs->find({username => 'me'})->TO_JSON;
    my $me_no_email = clone($me);
    # delete $me_no_email->{email_address};

    my @responses = (
        ['me',    '/api/users',    {want => \@all_users,  },],
        ['me',    '/api/users/me', {want => $me,          },],
        ['you',   '/api/users',    {want => \@all_users,  },],
        ['you',   '/api/users/me', {want => $me_no_email, },],
        ['noone', '/api/users',    {want => \@all_users,  },],
        ['noone', '/api/users/me', {want => $me_no_email, },],
    );
    for my $response (@responses) {
        my ($user, $route, $res) = @{$response};
        $self->add_route_test($route, $user, 'GET', {}, $res);
    }
    $self->add_route_readonly('/api/users',    '*');
    $self->add_route_readonly('/api/users/me', '*');

};

test '/public_datasets' => sub {
    my ($self) = @_;
    my @datasets = map {$_->TO_JSON} $self->schema->resultset('Dataset')->public->all;
    $self->add_route_test(
        '/api/public_datasets', '*', 'GET', {}, {want => \@datasets}
    );
    $self->add_route_readonly('/api/public_datasets', '*');
};

test '/public_pages' => sub {
    my ($self) = @_;
    my @pages = map {$_->TO_JSON} $self->schema->resultset('Page')->public->all;
    $self->add_route_test(
        '/api/public_pages', '*', 'GET', {}, {want => \@pages}
    );
    $self->add_route_readonly('/api/public_pages', '*');
};


# Authd routes
test '/user' => sub {
    my ($self) = @_;

    my $user_rs = $self->schema->resultset('User');
    my $me  = $user_rs->find({username => 'me'});
    my $you = $user_rs->find({username => 'you'});

    $self->add_route_test('/api/user', 'me', 'GET', {}, {want => $me->TO_JSON});
    $self->add_route_test('/api/user', 'you', 'GET', {}, {want => $you->TO_JSON});
    $self->add_route_readonly('/api/user', 'me+you');


    # I can see my datasets and create new ones.
    my $my_datasets = $me->datasets_rs;
    my @all_my_ds   = map {$_->TO_JSON} $my_datasets->all;
    my $my_new_ds   = {};
    $self->add_route_test('/api/user/datasets', 'me', 'GET', {}, {want => \@all_my_ds});
    fail("NOT IMPLEMENTED! me POST /api/user/datasets");
    # $self->add_route_test('/api/user/datasets', 'me', 'POST', $my_new_ds, [\302, {want => $my_new_ds}]);
    $self->add_route_bad_method('/api/user/datasets', 'me', 'PUT+DELETE', {});


    $self->reset_fixtures();
    $self->load_fixtures('init','api');

    # You can see your pages and create new ones.
    my $your_datasets = $you->datasets_rs;
    my @all_your_ds   = map {$_->TO_JSON} $your_datasets->all;
    my $your_new_ds   = {};
    $self->add_route_test('/api/user/datasets', 'you', 'GET', {}, {want => \@all_your_ds});
    fail("NOT IMPLEMENTED! you POST /api/user/datasets");
    # $self->add_route_test('/api/user/datasets', 'you', 'POST', $your_new_ds, [\302, {want => $your_new_ds}]);
    $self->add_route_bad_method('/api/user/datasets', 'you', 'PUT+DELETE', {});

    $self->reset_fixtures();
    $self->load_fixtures('init','api');

    # I can see my pages and create new ones
    my $my_pages     = $me->my_pages;
    my @all_my_pages = map {$_->TO_JSON} $my_pages->all;
    my $my_new_page  = {};
    $self->add_route_test('/api/user/pages', 'me', 'GET', {}, {want => \@all_my_pages});
    fail("NOT IMPLEMENTED! me POST /api/user/pages");
    # $self->add_route_test('/api/user/pages', 'me', 'POST', $my_new_page, [\302, {want => $my_new_page}]);
    $self->add_route_bad_method('/api/user/pages', 'me', 'PUT+DELETE', {});

    $self->reset_fixtures();
    $self->load_fixtures('init','api');

    # you have can see your pages and create new ones
    my $your_pages     = $you->my_pages;
    my @all_your_pages = map {$_->TO_JSON} $your_pages->all;
    my $your_new_page  = {};
    $self->add_route_test('/api/user/pages', 'you', 'GET', {}, {want => \@all_your_pages});
    fail("NOT IMPLEMENTED! you POST /api/user/pages");
    # $self->add_route_test('/api/user/pages', 'you', 'POST', $your_new_page, [\302, {want => $your_new_page}]);
    $self->add_route_bad_method('/api/user/pages', 'you', 'PUT+DELETE', {});

    $self->reset_fixtures();
    $self->load_fixtures('init','api');

    $self->add_route_needs_auth('/api/user', 'noone', '*', {});
    $self->add_route_needs_auth('/api/user/datasets', 'noone', '*', {});
    $self->add_route_needs_auth('/api/user/pages', 'noone', '*', {});

};


# read-write the logged-in users dataset
test '/datasets' => sub {
    my ($self) = @_;

    # /api/datasets redirects to /public_datasets
    my @all_datasets = map {$_->TO_JSON}
        $self->schema->resultset('Dataset')->public->all;
    $self->add_route_test(
        '/api/datasets', '*', 'GET', {}, {want => \@all_datasets}
    );
    $self->add_route_readonly('/api/datasets', '*');

    my %valid_ds_fields = map {$_ => 1} qw(name notes permission);
    my $user_rs = $self->schema->resultset('User');

    # I have full priviliges over my dataset
    my $me            = $user_rs->find({username => 'me'});
    my $my_datasets   = $me->datasets_rs;
    my $my_pub_ds     = $my_datasets->public->first->TO_JSON;
    my $my_pub_ds_id  = $my_pub_ds->{id};
    my $my_pub_update = clone($my_pub_ds);
    delete @{$my_pub_update}{
        grep {!$valid_ds_fields{$_}} keys %$my_pub_update
    };
    $my_pub_update->{notes} = "Moo moo quack quack";
    $self->add_route_test("/api/datasets/$my_pub_ds_id", 'me', 'GET', {}, {want => $my_pub_ds});
    $self->add_route_bad_method("/api/datasets/$my_pub_ds_id", 'me', 'POST', {});
    $self->add_route_test(
        "/api/datasets/$my_pub_ds_id", 'me', 'PUT', $my_pub_update, \204,
    );
    $my_pub_ds = $my_datasets->public->first->TO_JSON; # refresh timestamps
    $self->add_route_test(
        "/api/datasets/$my_pub_ds_id", 'me', 'GET', {}, {want => {
            %$my_pub_ds, description => $my_pub_update->{notes}
        }}
    );
    $self->add_route_test(
        "/api/datasets/$my_pub_ds_id", 'me', 'DELETE', {},
        sub {
            my ($self, $msg) = @_;
            ok !($my_datasets->find({id => $my_pub_ds_id})),
                "$msg: public dataset deleted";
        },
    );


    my $my_priv_ds     = $my_datasets->private->first->TO_JSON;
    my $my_priv_ds_id  = $my_priv_ds->{id};
    my $my_priv_update = clone($my_priv_ds);
    delete @{$my_priv_update}{
        grep {!$valid_ds_fields{$_}} keys %$my_priv_update
    };
    $my_priv_update->{notes} = "wumpa wumpa";
    $self->add_route_test("/api/datasets/$my_priv_ds_id", 'me', 'GET', {}, {want => $my_priv_ds});
    $self->add_route_bad_method("/api/datasets/$my_priv_ds_id", 'me', 'POST', {},);
    $self->add_route_test("/api/datasets/$my_priv_ds_id", 'me', 'PUT', $my_priv_update, \204);
    $my_priv_ds = $my_datasets->private->first->TO_JSON; # refresh timestamps
    $self->add_route_test(
        "/api/datasets/$my_priv_ds_id", 'me', 'GET', {}, {want => {
            %$my_priv_ds, description => $my_priv_update->{notes}
        }}
    );
    $self->add_route_test(
        "/api/datasets/$my_priv_ds_id", 'me',  'DELETE', {},
        sub {
            my ($self, $msg) = @_;
            ok !($my_datasets->find({id => $my_priv_ds_id})),
                "$msg: private dataset deleted";
        },
    );

    $self->reset_fixtures();
    $self->load_fixtures('init','api');

    # other users can see my public datasets, but nothing else
    # refetch public dataset after schema reset
    $my_pub_ds = $my_datasets->public->first->TO_JSON;
    $self->add_route_test("/api/datasets/$my_pub_ds_id", 'you+noone', 'GET', {}, {want => $my_pub_ds});
    $self->add_route_bad_method("/api/datasets/$my_pub_ds_id", 'you+noone', 'POST+PUT+DELETE', {});
    $self->add_route_not_found("/api/datasets/$my_priv_ds_id", 'you+noone', '*', {});
};


# mixed access to dataset properties
test '/datasets/1/columns' => sub {
    my ($self) = @_;

    my $user_rs     = $self->schema->resultset('User');
    my $me          = $user_rs->find({username => 'me'});
    my $my_datasets = $me->datasets_rs;

    # for me
    # GET    /ds/$public/columns  == want
    # POST   /ds/$public/columns  == want
    # PUT    /ds/$public/columns  == 405
    # DELETE /ds/$public/columns  == 405
    my $my_pub_ds      = $my_datasets->public->first;
    my $my_pub_ds_id   = $my_pub_ds->id;
    my @my_pub_ds_cols = map {$_->TO_JSON} $my_pub_ds->ds_columns_ordered->all;
    my $public_cols_url = "/api/datasets/$my_pub_ds_id/columns";
    $self->add_route_test(
        $public_cols_url, 'me', 'GET', {}, {want => \@my_pub_ds_cols}
    );
    fail("POST $public_cols_url Not Implemented!");
    $self->add_route_bad_method($public_cols_url, 'me', 'PUT+DELETE', {});
    $self->reset_fixtures();
    $self->load_fixtures('init','api');

    # for me
    # GET    /ds/$public/columns/$id  == want
    # POST   /ds/$public/columns/$id  == 405
    # PUT    /ds/$public/columns/$id  == want
    # DELETE /ds/$public/columns/$id  == 405
    my $my_pub_ds_col    = $my_pub_ds->ds_columns_ordered->first->TO_JSON;
    my $my_pub_ds_col_id = $my_pub_ds_col->{id};
    my $public_col_url
        = "/api/datasets/$my_pub_ds_id/columns/$my_pub_ds_col_id";
    $self->add_route_test(
        $public_col_url, 'me', 'GET', {}, {want => $my_pub_ds_col}
    );
    fail("PUT $public_col_url Not Implemented!");
    $self->add_route_bad_method($public_col_url, 'me', 'POST+DELETE', {});
    $self->reset_fixtures();
    $self->load_fixtures('init','api');

    # for me
    # GET    /ds/$private/columns  == want
    # POST   /ds/$private/columns  == want
    # PUT    /ds/$private/columns  == 405
    # DELETE /ds/$private/columns  == 405
    my $my_priv_ds      = $my_datasets->private->first;
    my $my_priv_ds_id   = $my_priv_ds->id;
    my @my_priv_ds_cols = map {$_->TO_JSON}
        $my_priv_ds->ds_columns_ordered->all;
    my $private_cols_url = "/api/datasets/$my_priv_ds_id/columns";
    $self->add_route_test(
        $private_cols_url, 'me', 'GET', {}, {want => \@my_priv_ds_cols}
    );
    fail("POST $private_cols_url Not Implemented!");
    $self->add_route_bad_method($private_cols_url, 'me', 'PUT+DELETE', {});
    $self->reset_fixtures();
    $self->load_fixtures('init','api');

    # for me
    # GET    /ds/$private/columns/$id == want
    # POST   /ds/$private/columns/$id == 405
    # PUT    /ds/$private/columns/$id == want
    # DELETE /ds/$private/columns/$id == 405
    my $my_priv_ds_col    = $my_priv_ds->ds_columns_ordered->first->TO_JSON;
    my $my_priv_ds_col_id = $my_priv_ds_col->{id};
    my $private_col_url
        = "/api/datasets/$my_priv_ds_id/columns/$my_priv_ds_col_id";
    $self->add_route_test(
        $private_col_url, 'me', 'GET', {}, {want => $my_priv_ds_col}
    );
    fail("PUT $private_col_url Not Implemented!");
    $self->add_route_bad_method($private_col_url, 'me', 'POST+DELETE', {});
    $self->reset_fixtures();
    $self->load_fixtures('init','api');


    # you + noone
    # other users can see my public datasets, but nothing else
    # refetch public columns after schema reset
    @my_pub_ds_cols = map {$_->TO_JSON} $my_pub_ds->ds_columns_ordered->all;
    $self->add_route_test(
        $public_cols_url, 'you+noone', 'GET', {}, {want => \@my_pub_ds_cols}
    );
    $self->add_route_bad_method(
        $public_cols_url, 'you+noone', 'POST+PUT+DELETE', {}
    );
    $self->add_route_not_found($private_cols_url, 'you+noone', '*', {});

    # refetch public column after schema reset
    $my_pub_ds_col = $my_pub_ds->ds_columns_ordered->first->TO_JSON;
    $self->add_route_test(
        $public_col_url, 'you+noone', 'GET', {}, {want => $my_pub_ds_col}
    );
    $self->add_route_bad_method(
        $public_col_url, 'you+noone', 'POST+PUT+DELETE', {}
    );
    $self->add_route_not_found($private_col_url, 'you+noone', '*', {});
};


test '/datasets/1/pages' => sub {
    my ($self) = @_;

    my $my_datasets = $self->schema->resultset('User')
        ->find({username => 'me'})->datasets_rs;

    # I can see all my pages for my public dataset
    my $my_pub_ds     = $my_datasets->public->first;
    my $my_pub_ds_id  = $my_pub_ds->id;
    my @my_pub_ds_pages = map {$_->TO_JSON} $my_pub_ds->pages_rs->all;
    $self->add_route_test(
        "/api/datasets/$my_pub_ds_id/pages", 'me', 'GET', {},
        { want => \@my_pub_ds_pages },
    );
    $self->add_route_readonly("/api/datasets/$my_pub_ds_id/pages", 'me');

    # I can see all my pages for my private dataset
    my $my_priv_ds     = $my_datasets->private->first;
    my $my_priv_ds_id  = $my_priv_ds->id;
    my @my_priv_ds_pages = map {$_->TO_JSON} $my_priv_ds->pages_rs->all;
    $self->add_route_test(
        "/api/datasets/$my_priv_ds_id/pages", 'me', 'GET', {},
        { want => \@my_priv_ds_pages },
    );
    $self->add_route_readonly("/api/datasets/$my_priv_ds_id/pages", 'me');

    # other users can see public pages of public datasets, but nothing
    # for private datasets
    my @my_pub_ds_pub_pages = map {$_->TO_JSON} $my_pub_ds->pages_rs->public->all;
    $self->add_route_test(
        "/api/datasets/$my_pub_ds_id/pages", 'you+noone', 'GET', {},
        { want => \@my_pub_ds_pub_pages, }
    );
    $self->add_route_bad_method("/api/datasets/$my_pub_ds_id/pages", 'you+noone', 'POST+PUT+DELETE', {});
    $self->add_route_not_found("/api/datasets/$my_priv_ds_id/pages", 'you+noone', '*', {});
};


# mixed access to page properties
test '/pages' => sub {
    my ($self) = @_;

    my @all_pages = map {$_->TO_JSON}
        $self->schema->resultset('Page')->public->all;
    $self->add_route_test(
        '/api/pages', '*', 'GET', {}, {want => \@all_pages}
    );
    $self->add_route_readonly('/api/pages', '*');

    my %valid_page_fields = map {$_ => 1} qw(title preamble postamble permission);
    my $user_rs = $self->schema->resultset('User');

    # I have full priviliges over my dataset
    my $me             = $user_rs->find({username => 'me'});
    my $my_pages       = $me->my_pages;
    my $my_pub_page    = $my_pages->public->first->TO_JSON;
    my $my_pub_page_id = $my_pub_page->{id};
    my $my_pub_update  = clone($my_pub_page);
    delete @{$my_pub_update}{
        grep {!$valid_page_fields{$_}} keys %$my_pub_update
    };
    $my_pub_update->{title} = "Moo moo quack quack";
    $self->add_route_test("/api/pages/$my_pub_page_id", 'me', 'GET', {}, {want => $my_pub_page});
    $self->add_route_bad_method("/api/pages/$my_pub_page_id", 'me', 'POST', {});
    $self->add_route_test(
        "/api/pages/$my_pub_page_id", 'me', 'PUT', $my_pub_update, \204,
    );
    $my_pub_page = $my_pages->find({id => $my_pub_page_id})
        ->TO_JSON; # refresh timestamps
    $self->add_route_test(
        "/api/pages/$my_pub_page_id", 'me', 'GET', {}, {want => {
            %$my_pub_page, title => $my_pub_update->{title}
        }}
    );
    $self->add_route_test(
        "/api/pages/$my_pub_page_id", 'me', 'DELETE', {},
        sub {
            my ($self, $msg) = @_;
            ok !($my_pages->find({id => $my_pub_page_id})),
                "$msg: public page deleted";
        },
    );


    my $my_priv_page     = $my_pages->private->first->TO_JSON;
    my $my_priv_page_id  = $my_priv_page->{id};
    my $my_priv_update = clone($my_priv_page);
    delete @{$my_priv_update}{
        grep {!$valid_page_fields{$_}} keys %$my_priv_update
    };
    $my_priv_update->{title} = "wumpa wumpa";
    $self->add_route_test("/api/pages/$my_priv_page_id", 'me', 'GET', {}, {want => $my_priv_page});
    $self->add_route_bad_method("/api/pages/$my_priv_page_id", 'me', 'POST', {},);
    $self->add_route_test("/api/pages/$my_priv_page_id", 'me', 'PUT', $my_priv_update, \204);
    $my_priv_page = $my_pages->find({id => $my_priv_page_id})
        ->TO_JSON; # refresh timestamps
    $self->add_route_test(
        "/api/pages/$my_priv_page_id", 'me', 'GET', {}, {want => {
            %$my_priv_page, title => $my_priv_update->{title}
        }}
    );
    $self->add_route_test(
        "/api/pages/$my_priv_page_id", 'me',  'DELETE', {},
        sub {
            my ($self, $msg) = @_;
            ok !($my_pages->find({id => $my_priv_page_id})),
                "$msg: private page deleted";
        },
    );

    $self->reset_fixtures();
    $self->load_fixtures('init','api');

    # other users can see my public pages, but nothing else
    my $my_pub_page2 = $my_pages->public->first->TO_JSON; # fixtures have been reset
    $self->add_route_test("/api/pages/$my_pub_page_id", 'you+noone', 'GET', {}, {want => $my_pub_page2});
    $self->add_route_bad_method("/api/pages/$my_pub_page_id", 'you+noone', 'POST+PUT+DELETE', {});
    $self->add_route_not_found("/api/pages/$my_priv_page_id", 'you+noone', '*', {});
};


test '/pages/1/columns' => sub {
    my ($self) = @_;

    my $user_rs  = $self->schema->resultset('User');
    my $me       = $user_rs->find({username => 'me'});
    my $my_pages = $me->my_pages;

    # for me
    # GET    /pages/$public/columns  == want
    # POST   /pages/$public/columns  == want
    # PUT    /pages/$public/columns  == 405
    # DELETE /pages/$public/columns  == want
    my $my_pub_page      = $my_pages->public->first;
    my $my_pub_page_id   = $my_pub_page->id;
    my @my_pub_page_cols = map {$_->TO_JSON}
        $my_pub_page->page_columns_ordered->all;
    my $public_cols_url   = "/api/pages/$my_pub_page_id/columns";
    $self->add_route_test(
        $public_cols_url, 'me', 'GET', {}, {want => \@my_pub_page_cols}
    );
    fail("POST $public_cols_url Not Implemented!");
    $self->add_route_bad_method($public_cols_url, 'me', 'PUT', {});
    fail("DELETE $public_cols_url Not Implemented!");
    $self->reset_fixtures();
    $self->load_fixtures('init','api');

    # for me
    # GET    /pages/$public/columns/$id  == want
    # POST   /pages/$public/columns/$id  == 405
    # PUT    /pages/$public/columns/$id  == want
    # DELETE /pages/$public/columns/$id  == want
    my $my_pub_page_col    = $my_pub_page->page_columns_ordered->first->TO_JSON;
    my $my_pub_page_col_id = $my_pub_page_col->{id};
    my $public_col_url
        = "/api/pages/$my_pub_page_id/columns/$my_pub_page_col_id";
    $self->add_route_test(
        $public_col_url, 'me', 'GET', {}, {want => $my_pub_page_col}
    );
    $self->add_route_bad_method($public_col_url, 'me', 'POST', {});
    fail("PUT $public_col_url Not Implemented!");
    fail("DELETE $public_col_url Not Implemented!");
    $self->reset_fixtures();
    $self->load_fixtures('init','api');

    # for me
    # GET    /pages/$private/columns  == want
    # POST   /pages/$private/columns  == want
    # PUT    /pages/$private/columns  == 405
    # DELETE /pages/$private/columns  == want
    my $my_priv_page      = $my_pages->private->first;
    my $my_priv_page_id   = $my_priv_page->id;
    my @my_priv_page_cols = map {$_->TO_JSON}
        $my_priv_page->page_columns_ordered->all;
    my $private_cols_url = "/api/pages/$my_priv_page_id/columns";
    $self->add_route_test(
        $private_cols_url, 'me', 'GET', {}, {want => \@my_priv_page_cols}
    );
    fail("POST $private_cols_url Not Implemented!");
    $self->add_route_bad_method($private_cols_url, 'me', 'PUT', {});
    fail("DELETE $private_cols_url Not Implemented!");
    $self->reset_fixtures();
    $self->load_fixtures('init','api');

    # for me
    # GET    /pags/$private/columns/$id == want
    # POST   /pags/$private/columns/$id == 405
    # PUT    /pags/$private/columns/$id == want
    # DELETE /pags/$private/columns/$id == want
    my $my_priv_page_col    = $my_priv_page->page_columns_ordered->first->TO_JSON;
    my $my_priv_page_col_id = $my_priv_page_col->{id};
    my $private_col_url
        = "/api/pages/$my_priv_page_id/columns/$my_priv_page_col_id";
    $self->add_route_test(
        $private_col_url, 'me', 'GET', {}, {want => $my_priv_page_col}
    );
    $self->add_route_bad_method($private_col_url, 'me', 'POST', {});
    fail("PUT $private_col_url Not Implemented!");
    fail("DELETE $private_col_url Not Implemented!");
    $self->reset_fixtures();
    $self->load_fixtures('init','api');

    # you + noone
    # other users can see my public datasets, but nothing else
    # refetch public columns after schema reset
    @my_pub_page_cols = map {$_->TO_JSON}
        $my_pub_page->page_columns_ordered->all;
    $self->add_route_test(
        $public_cols_url, 'you+noone', 'GET', {}, {want => \@my_pub_page_cols}
    );
    $self->add_route_bad_method(
        $public_cols_url, 'you+noone', 'POST+PUT+DELETE', {}
    );
    $self->add_route_not_found($private_cols_url, 'you+noone', '*', {});

    # refetch public column after schema reset
    $my_pub_page_col = $my_pub_page->page_columns_ordered->first->TO_JSON;
    $self->add_route_test(
        $public_col_url, 'you+noone', 'GET', {}, {want => $my_pub_page_col}
    );
    $self->add_route_bad_method(
        $public_col_url, 'you+noone', 'POST+PUT+DELETE', {}
    );
    $self->add_route_not_found($private_col_url, 'you+noone', '*', {});
};



test '/datasets/1/data'    => sub { fail('not done'); };


# services
test '/templates'  => sub { fail('not done'); };
test '/types'      => sub { fail('not done'); };
test '/sitelinker' => sub { fail('not done'); };
test '/lookup'     => sub { fail('not done'); };



# report untested routes
after teardown => sub {
    my ($self) = @_;

    my $table = Text::Table->new(qw(Route User Method Tested?));
    $table->rule('-', '+');
    for my $route (@{ $self->routes }) {
        for my $user (@{ $self->my_users }) {
            for my $method (@{ $self->methods }) {
                my $seen = $self->seen_test($route, $user, $method);
                if (not $seen) {
                    $table->add($route, $user, $method, 0+$seen);
                }
            }
        }
    }

    diag "Test Results";
    diag $table->table;
};


run_me();
done_testing();


# HELPER METHODS

sub _build_routes { return []; }
sub add_route {
    my ($self, $route) = @_;
    my @routes = @{ $self->routes };
    if (List::MoreUtils::all {$route ne $_} @routes) {
        push @{ $self->routes }, $route;
    }
}


sub _build_my_users { return [qw(me you noone)]; }
sub add_my_user {
    my ($self, $user) = @_;
    my @my_users = @{ $self->my_users };
    if  (! List::MoreUtils::any {$_ eq $user} @my_users) {
        push @{ $self->my_users }, $user;
    }
}
sub _expand_my_users {
    my ($self, $users) = @_;
    return $users eq '*'  ? @{ $self->my_users }
        : $users =~ m/\+/ ? split(/\+/, $users)
        :                   do { $self->add_my_user($users); ($users); };
}


sub _build_methods { return [qw(GET POST PUT DELETE)]; }
sub add_method {
    my ($self, $method) = @_;
    my @methods = @{ $self->methods };
    if  (! List::MoreUtils::any {$_ eq $method} @methods) {
        push @{ $self->methods }, $method;
    }
}
sub _expand_methods {
    my ($self, $methods) = @_;
    return $methods eq '*'  ? @{ $self->methods }
        : $methods =~ m/\+/ ? split(/\+/, $methods)
        :                     do { $self->add_method($methods); ($methods); };
}


sub set_route_prefix {}

sub add_route_test {
    my ($self, $route, $users, $methods, $object, $test) = @_;

    $self->add_route($route);

    my @users = $self->_expand_my_users($users);
    my @methods = $self->_expand_methods($methods);

    my $test_sub = $self->_expand_test($test);
    for my $user (@users) {

        $self->login( @{$users{$user}}{qw(username password)} )
            unless ($user eq 'noone');
        for my $method (@methods) {
            my $test_method = "_${method}_json";
            diag "*** $user $method $route" if ($self->debug);
            $self->$test_method($route, $object);
            diag "  === " . substr($self->mech->content, 0, 30) if ($self->debug);
            $test_sub->($self, "$user $method $route");
            $self->_tests->{ $self->test_id( $route, $user, $method ) }++;
        }
        $self->logout  unless ($user eq 'noone');

    }
}
sub add_route_needs_auth { shift->add_route_test(@_, \401); }
sub add_route_forbidden  { shift->add_route_test(@_, \403); }
sub add_route_not_found  { shift->add_route_test(@_, \404); }
sub add_route_bad_method { shift->add_route_test(@_, \405); }
sub add_route_readonly   { shift->add_route_test(@_, 'POST+PUT+DELETE', {}, \405); }

sub _expand_test {
    my ($self, $test_ref) = @_;

    my $reftype = ref $test_ref;
    if ($reftype eq 'SCALAR') {
        return sub {
            my ($self, $id) = @_;
            is $self->mech->status, $$test_ref,
                "$id: response is: $$test_ref";
        };
    }
    elsif ($reftype eq 'CODE') {
        return $test_ref;
    }
    elsif ($reftype eq 'ARRAY') {
        my @subs = map {$self->_expand_test($_)} @$test_ref;
        return sub {
            my ($self, $id) = @_;
            $_->($self, $id) for (@subs);
        };
    }
    elsif ( $reftype eq 'HASH') {
        return sub {
            my ($self, $id) = @_;
            is_deeply $self->decode_json($self->mech->content),
                $test_ref->{want}, "$id: response is as expected";
        }
    }

    die "Unhandled test ref type: " . $test_ref;
}


sub _build__tests { return {}; }
sub test_id { shift; return join(',', @_); }
sub seen_test {
    my $self = shift;
    return exists $self->_tests->{ $self->test_id(@_) };
}



sub _GET_json {
    my ($self, $url) = @_;
    my $r = GET($url, 'Accept' => 'application/json');
    $self->mech->request($r);
}

sub _POST_json {
    my ($self, $url, $object) = @_;
    my $r = POST(
        $url, 'Accept' => 'application/json',
        'Content-Type' => 'application/json',
        Content => $self->encode_json($object),
    );
    $self->mech->request($r);
}

sub _PUT_json {
    my ($self, $url, $object) = @_;
    my $r = PUT(
        $url, 'Accept' => 'application/json',
        'Content-Type' => 'application/json',
        Content => $self->encode_json($object),
    );
    $self->mech->request($r);
}

sub _DELETE_json {
    my ($self, $url) = @_;
    my $r = DELETE($url, 'Accept' => 'application/json',);
    $self->mech->request($r);
}


__END__
