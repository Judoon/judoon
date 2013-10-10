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

    my $user_url = '/api/user';
    $self->add_route_test($user_url, 'me', 'GET', {}, {want => $me->TO_JSON });
    $self->add_route_test($user_url, 'me', 'PUT', {name => 'Boo'}, \204);
    $self->add_route_test($user_url, 'me', 'GET', {}, {want => {
        %{$me->discard_changes->TO_JSON}, name => 'Boo',
    }});
    $self->add_route_test($user_url, 'you', 'GET', {}, {want => $you->TO_JSON});
    $self->add_route_test($user_url, 'you', 'PUT', {name => 'Moo'}, \204);
    $self->add_route_test($user_url, 'you', 'GET', {}, {want => {
        %{$you->discard_changes->TO_JSON}, name => 'Moo',
    }});
    $self->add_route_bad_method($user_url, 'me+you', 'POST+DELETE', {});
    $self->reset_fixtures();
    $self->load_fixtures('init','api');


    my $ds_url   = '/api/user/datasets';
    my $page_url = '/api/user/pages';
    for my $user ($me, $you) {
        my $name = $user->username;

        # User can see their datasets and create new ones.
        my $datasets = $user->datasets_rs;
        my @all_ds   = map {$_->TO_JSON} $datasets->all;
        my $new_ds   = {};
        $self->add_route_test($ds_url, $name, 'GET', {}, {want => \@all_ds});
        fail("NOT IMPLEMENTED! $name POST $ds_url");
        # $self->add_route_test($ds_url, 'me', 'POST', $new_ds, [\201, {want => $new_ds}]);
        $self->add_route_bad_method($ds_url, $name, 'PUT+DELETE', {});
        $self->reset_fixtures();
        $self->load_fixtures('init','api');

        # User can see their pages and create new ones
        my $pages     = $user->my_pages;
        my @all_pages = map {$_->TO_JSON} $pages->all;
        my $new_page  = {
            dataset_id => $all_ds[0]->{id},
            title      => 'Brand New Page',
            preamble   => 'Hello and welcome to',
            postamble  => 'thanks and good bye',
        };
        $self->add_route_test($page_url, $name, 'GET', {}, {want => \@all_pages});
        $self->add_route_created($page_url, $name, 'POST', $new_page);
        $self->add_route_bad_method($page_url, $name, 'PUT+DELETE', {});
        $self->reset_fixtures();
        $self->load_fixtures('init','api');
    }

    $self->add_route_needs_auth($user_url, 'noone', '*', {});
    $self->add_route_needs_auth($ds_url,   'noone', '*', {});
    $self->add_route_needs_auth($page_url, 'noone', '*', {});
};


# read-write the logged-in users dataset
test '/datasets' => sub {
    my ($self) = @_;

    # /api/datasets redirects to /public_datasets
    my @all_datasets = map {$_->TO_JSON}
        $self->schema->resultset('Dataset')->public->all;
    $self->add_route_redirects('/api/datasets', '*', 'GET', {});
    $self->add_route_test(
        '/api/datasets', '*', 'GET', {}, {want => \@all_datasets}
    );
    $self->add_route_readonly('/api/datasets', '*');


    # I have full priviliges over my datasets
    my $user_rs         = $self->schema->resultset('User');
    my $me              = $user_rs->find({username => 'me'});
    my $my_datasets     = $me->datasets_rs;
    my @valid_ds_fields = qw(name notes permission);
    my %urls            = (public => '', private => '');
    my @datasets        = (
        # type       dataset
        [ 'public',  $my_datasets->public->first->TO_JSON,  ],
        [ 'private', $my_datasets->private->first->TO_JSON, ],
    );
    for my $ds_test (@datasets) {
        my ($type, $ds) = @$ds_test;
        my $ds_id       = $ds->{id};
        my $ds_url      = "/api/datasets/$ds_id";
        my $update      = {
            (map {$_ => $ds->{$_}} @valid_ds_fields),
            notes => "Moo moo quack quack",
        };

        $self->add_route_test($ds_url, 'me', 'GET', {}, {want => $ds});
        $self->add_route_bad_method($ds_url, 'me', 'POST', {});
        $self->add_route_test($ds_url, 'me', 'PUT', $update, \204,);
        $ds = $my_datasets->find({id => $ds_id})->TO_JSON; # refresh timestamps
        $self->add_route_test($ds_url, 'me', 'GET', {}, {want => {
            %$ds, description => $update->{notes}
        }});
        $self->add_route_test($ds_url, 'me', 'DELETE', {},
            sub {
                my ($self, $msg) = @_;
                ok !($my_datasets->find({id => $ds_id})),
                    "$msg: $type dataset deleted";
            },
        );
        $urls{$type}  = $ds_url;
    }

    $self->reset_fixtures();
    $self->load_fixtures('init','api');

    # other users can see my public datasets, but nothing else
    my $my_pub_ds = $my_datasets->find({id => $datasets[0][1]->{id}})->TO_JSON;
    $self->add_route_test($urls{public}, 'you+noone', 'GET', {}, {want => $my_pub_ds});
    $self->add_route_bad_method($urls{public}, 'you+noone', 'POST+PUT+DELETE', {});
    $self->add_route_not_found($urls{private}, 'you+noone', '*', {});
};


# mixed access to dataset properties
test '/datasets/1/columns' => sub {
    my ($self) = @_;

    my $user_rs      = $self->schema->resultset('User');
    my $me           = $user_rs->find({username => 'me'});
    my $my_datasets  = $me->datasets_rs;
    my @dscol_fields = qw(data_type);
    my %urls;
    my @dscolumns = (
        # type       dataset
        [ 'public',  $my_datasets->public->first,  ],
        [ 'private', $my_datasets->private->first, ],
    );

    for my $dscol_test (@dscolumns) {
        my ($type, $ds) = @$dscol_test;
        my $ds_id       = $ds->id;

        # GET    /datasets/$ds_id/columns == want
        # POST   /datasets/$ds_id/columns == want
        # PUT    /datasets/$ds_id/columns == 405
        # DELETE /datasets/$ds_id/columns == 405
        my @ds_cols       = map {$_->TO_JSON} $ds->ds_columns_ordered->all;
        my $cols_url      = "/api/datasets/$ds_id/columns";
        my $other_ds      = $my_datasets->search({id => {'!=' => $ds_id}})->first;
        my @other_ds_cols = map {$_->TO_JSON}
            $other_ds->ds_columns_ordered->slice(0,1)->all;
        my $new_col       = {
          dataset_id         => $ds_id,
          new_col_name       => 'Derived Column',
          this_table_id      => $ds_id,
          that_table_id      => 'internal_' . $other_ds->id,
          this_joincol_id    => $ds_cols[0]->{shortname},
          that_joincol_id    => $other_ds_cols[0]->{shortname},
          that_selectcol_id  => $other_ds_cols[1]->{shortname},
        };
        my $compare_col = {
            dataset_id => $ds_id,
            name       => $new_col->{new_col_name},
        };
        $self->add_route_test($cols_url, 'me', 'GET', {}, {want => \@ds_cols});
        $self->add_route_created($cols_url, 'me', 'POST', $new_col, $compare_col);
        $self->add_route_bad_method($cols_url, 'me', 'PUT+DELETE', {});
        $self->reset_fixtures();
        $self->load_fixtures('init','api');

        # GET    /datasets/$ds_id/columns/$col_id == want
        # POST   /datasets/$ds_id/columns/$col_id == 405
        # PUT    /datasets/$ds_id/columns/$col_id == want
        # DELETE /datasets/$ds_id/columns/$col_id == 405
        my $ds_col    = $ds->ds_columns_ordered->first->TO_JSON;
        my $ds_col_id = $ds_col->{id};
        my $col_url   = "$cols_url/$ds_col_id";
        my $update    = {
            (map {$_ => $ds_col->{$_}} @dscol_fields),
            data_type => 'Biology_Accession_Entrez_GeneSymbol',
        };
        $self->add_route_test($col_url, 'me', 'GET', {}, {want => $ds_col});
        $self->add_route_test($col_url, 'me', 'PUT', $update, \204);
        $ds_col = $ds->ds_columns->find({id => $ds_col_id})->TO_JSON; # refresh timestamps
        $self->add_route_test($col_url, 'me', 'GET', {}, {want => {
            %$ds_col, data_type => $update->{data_type}
        }});
        $self->add_route_bad_method($col_url, 'me', 'POST+DELETE', {});
        $self->reset_fixtures();
        $self->load_fixtures('init','api');

        $urls{$type} = {
            set  => $cols_url,
            item => $col_url,
        };
    }


    # you + noone
    # other users can see my public datasets, but nothing else
    # refetch public columns after schema reset
    my @pub_ds_cols = map {$_->TO_JSON} $dscolumns[0][1]->ds_columns_ordered->all;
    $self->add_route_test(
        $urls{public}{set}, 'you+noone', 'GET', {}, {want => \@pub_ds_cols}
    );
    $self->add_route_bad_method(
        $urls{public}{set}, 'you+noone', 'POST+PUT+DELETE', {}
    );
    $self->add_route_not_found($urls{private}{set}, 'you+noone', '*', {});

    # refetch public column after schema reset
    my $pub_ds_col = $dscolumns[0][1]->ds_columns_ordered->first->TO_JSON;
    $self->add_route_test(
        $urls{public}{item}, 'you+noone', 'GET', {}, {want => $pub_ds_col}
    );
    $self->add_route_bad_method(
        $urls{public}{item}, 'you+noone', 'POST+PUT+DELETE', {}
    );
    $self->add_route_not_found($urls{private}{item}, 'you+noone', '*', {});
};


test '/datasets/1/data' => sub {
    my ($self) = @_;

    my $my_datasets = $self->schema->resultset('User')
        ->find({username => 'me'})->datasets_rs;
    my @tests = (
        ['public',  $my_datasets->public->first,  ],
        ['private', $my_datasets->private->first, ],
    );
    my %urls;
    # I can see all my data for my datasets
    for my $test (@tests) {
        my ($type, $ds) = @$test;
        my $ds_id       = $ds->id;

        my $data_table = $ds->data_table({shortname => 1});
        my $headers    = shift @$data_table;
        my @data       = map {{List::MoreUtils::zip @$headers, @$_}}
            @$data_table;
        my $data_url   = "/api/datasets/$ds_id/data";
        $self->add_route_test($data_url, 'me', 'GET', {},
            sub {
                my ($self, $msg) = @_;
                is_deeply
                    $self->decode_json($self->mech->content)->{tmplData},
                    \@data, "$msg: got correct dataset data";
            }
        );

        $self->add_route_readonly($data_url, 'me');
        $urls{$type} = $data_url;
    }


    # other users can see public pages of public datasets, but nothing
    # for private datasets
    my $pub_data_table = $tests[0][1]->data_table({shortname => 1});
    my $pub_headers    = shift @$pub_data_table;
    my @pub_data       = map {{List::MoreUtils::zip @$pub_headers, @$_}}
        @$pub_data_table;
    $self->add_route_test(
        $urls{public}, 'you+noone', 'GET', {},
        sub {
            my ($self, $msg) = @_;
            is_deeply
                $self->decode_json($self->mech->content)->{tmplData},
                \@pub_data, "$msg: got correct dataset data";
        }
    );
    $self->add_route_bad_method($urls{public}, 'you+noone', 'POST+PUT+DELETE', {});
    $self->add_route_not_found($urls{private}, 'you+noone', '*', {});
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

    # /api/pages redirects to /public_pages
    my @all_pages = map {$_->TO_JSON}
        $self->schema->resultset('Page')->public->all;
    $self->add_route_redirects('/api/pages', '*', 'GET', {});
    $self->add_route_test(
        '/api/pages', '*', 'GET', {}, {want => \@all_pages}
    );
    $self->add_route_readonly('/api/pages', '*');


    # I have full priviliges over my pages
    my $user_rs           = $self->schema->resultset('User');
    my $me                = $user_rs->find({username => 'me'});
    my $my_pages          = $me->my_pages;
    my @valid_page_fields = qw(title preamble postamble permission);
    my %urls              = (public => '', private => '');
    my @pages             = (
        # type       page
        [ 'public',  $my_pages->public->first->TO_JSON,  ],
        [ 'private', $my_pages->private->first->TO_JSON, ],
    );
    for my $page_test (@pages) {
        my ($type, $page) = @$page_test;
        my $page_id  = $page->{id};
        my $page_url = "/api/pages/$page_id";
        my $update   = {
            (map {$_ => $page->{$_}} @valid_page_fields),
            title => "Moo moo quack quack",
        };
        $self->add_route_test($page_url, 'me', 'GET', {}, {want => $page});
        $self->add_route_bad_method($page_url, 'me', 'POST', {});
        $self->add_route_test($page_url, 'me', 'PUT', $update, \204);
        $page = $my_pages->find({id => $page_id})->TO_JSON; # refresh timestamps
        $self->add_route_test($page_url, 'me', 'GET', {}, {want => {
            %$page, title => $update->{title}
        }});
        $self->add_route_test($page_url, 'me', 'DELETE', {},
            sub {
                my ($self, $msg) = @_;
                ok !($my_pages->find({id => $page_id})),
                    "$msg: $type page deleted";
            },
        );

        $urls{$type} = $page_url;
    }

    $self->reset_fixtures();
    $self->load_fixtures('init','api');

    # other users can see my public pages, but nothing else
    my $my_pub_page = $my_pages->find({id => $pages[0][1]->{id}})->TO_JSON;
    $self->add_route_test($urls{public}, 'you+noone', 'GET', {}, {want => $my_pub_page});
    $self->add_route_bad_method($urls{public}, 'you+noone', 'POST+PUT+DELETE', {});
    $self->add_route_not_found($urls{private}, 'you+noone', '*', {});
};


test '/pages/1/columns' => sub {
    my ($self) = @_;

    my $user_rs        = $self->schema->resultset('User');
    my $me             = $user_rs->find({username => 'me'});
    my $my_pages       = $me->my_pages;
    my @pagecol_fields = qw(title template);
    my %urls;
    my @pages = (
        # type       dataset
        [ 'public',  $my_pages->public->first,  ],
        [ 'private', $my_pages->private->first, ],
    );


    for my $page_test (@pages) {
        my ($type, $page) = @$page_test;
        my $page_id       = $page->id;

        # GET    /pages/$page_id/columns  == want
        # POST   /pages/$page_id/columns  == want
        # PUT    /pages/$page_id/columns  == 405
        # DELETE /pages/$page_id/columns  == want
        my @page_cols = map {$_->TO_JSON} $page->page_columns_ordered->all;
        my $cols_url  = "/api/pages/$page_id/columns";
        $self->add_route_test($cols_url, 'me', 'GET', {}, {want => \@page_cols});
        my $new_col = {title => "I'm new!", template => ""};
        $self->add_route_created($cols_url, 'me', 'POST', $new_col);
        $self->add_route_bad_method($cols_url, 'me', 'PUT', {});
        $self->add_route_test($cols_url, 'me', 'DELETE', {},
            sub {
                my ($self, $msg) = @_;
                is_deeply [$page->page_columns->all], [],
                    "$msg: $type page columns deleted";
            }
        );
        $self->reset_fixtures();
        $self->load_fixtures('init','api');

        # GET    /pages/$page_id/columns/$col_id  == want
        # POST   /pages/$page_id/columns/$col_id  == 405
        # PUT    /pages/$page_id/columns/$col_id  == want
        # DELETE /pages/$page_id/columns/$col_id  == want
        my $page_col    = $page->page_columns_ordered->first->TO_JSON;
        my $page_col_id = $page_col->{id};
        my $col_url     = "/api/pages/$page_id/columns/$page_col_id";
        my $update      = {
            (map {$_ => $page_col->{$_}} @pagecol_fields),
            title => 'HaberDasher',
        };
        $self->add_route_test($col_url, 'me', 'GET', {}, {want => $page_col});
        $self->add_route_bad_method($col_url, 'me', 'POST', {});
        $self->add_route_test($col_url, 'me', 'PUT', $update, \204);
        $page_col = $page->page_columns->find({id => $page_col_id})->TO_JSON; # refresh timestamps
        $self->add_route_test($col_url, 'me', 'GET', {}, {want => {
            %$page_col, title => $update->{title}
        }});
        $self->add_route_test(
            $col_url, 'me', 'DELETE', {}, sub {
                my ($self, $msg) = @_;
                ok !($page->page_columns->find({id => $page_col_id})),
                    "$msg: $type dataset deleted";
            }
        );
        $self->reset_fixtures();
        $self->load_fixtures('init','api');

        $urls{$type} = {set => $cols_url, item => $col_url};
    }


    # you + noone
    # other users can see my public datasets, but nothing else
    # refetch public columns after schema reset
    my @pub_page_cols = map {$_->TO_JSON}
        $pages[0][1]->page_columns_ordered->all;
    $self->add_route_test(
        $urls{public}{set}, 'you+noone', 'GET', {}, {want => \@pub_page_cols}
    );
    $self->add_route_bad_method(
        $urls{public}{set}, 'you+noone', 'POST+PUT+DELETE', {}
    );
    $self->add_route_not_found($urls{private}{set}, 'you+noone', '*', {});

    # refetch public column after schema reset
    my $pub_page_col = $pages[0][1]->page_columns_ordered->first->TO_JSON;
    $self->add_route_test(
        $urls{public}{item}, 'you+noone', 'GET', {}, {want => $pub_page_col}
    );
    $self->add_route_bad_method(
        $urls{public}{item}, 'you+noone', 'POST+PUT+DELETE', {}
    );
    $self->add_route_not_found($urls{private}{item}, 'you+noone', '*', {});
};





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

sub add_route_created {
    my ($self, $url, $user, $method, $object, $compare_obj) = @_;
    my $expect = $compare_obj || $object;
    $self->add_route_test($url, $user, $method, $object, [
        \201,
        sub {
            my ($self, $msg) = @_;
            my $loc = $self->mech->res->header('Location');
            $self->_GET_json($loc);
            my $new_obj = $self->decode_json($self->mech->content);
            is_deeply {map {$_ => $new_obj->{$_}} keys %$expect},
                $expect, '  ...new object was created!';
        },
    ]);
}

sub add_route_redirects {
    my ($self) = shift;
    my $req_redir = $self->mech->requests_redirectable();
    $self->mech->requests_redirectable([]);
    $self->add_route_test(@_, \302);
    $self->mech->requests_redirectable($req_redir);
}


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
