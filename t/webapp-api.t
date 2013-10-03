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


# readonly access to public datasets
test '/datasets' => sub { fail('not done'); };
test '/datasets/1/columns' => sub { fail('not done'); };
test '/datasets/1/pages' => sub { fail('not done'); };
test '/datasets/1/data' => sub { fail('not done'); };

# readonly access to public pages
test '/pages' => sub { fail('not done'); };
test '/pages/1/columns' => sub { fail('not done'); };



test '/user' => sub { fail('not done'); };


# read-write the logged-in users dataset
test '/user/dataset' => sub {
    my ($self) = @_;

    # I have full priviliges over my dataset
    my $me = $self->schema->resultset('User')->find({username => 'me'});
    my $my_datasets = $me->datasets_rs;
    my @all_my_ds = map {$_->TO_JSON} $my_datasets->all;
    my $my_new_ds = {};
    $self->add_route_test('/api/user/datasets', 'me', 'GET',    {}, {want => \@all_my_ds}, );
    # fixme: implement these:
    # $self->add_route_test('/api/user/datasets', 'me', 'POST',   {}, [\302, {want => $my_new_ds}],    );
    $self->add_route_test('/api/user/datasets', 'me', 'PUT',    {}, \405, );
    $self->add_route_test(
        '/api/user/datasets', 'me', 'DELETE', {},
        sub {
            my ($self, $msg) = @_;
            is_deeply [$my_datasets->all], [], "$msg: all datasets deleted";
        },
    );

    $self->reset_fixtures();
    $self->load_fixtures('init','api');

    my %valid_ds_fields = map {$_ => 1} qw(name notes permission);
    my $my_pub_ds     = $my_datasets->public->first->TO_JSON;
    my $my_pub_ds_id  = $my_pub_ds->{id};
    my $my_pub_update = clone($my_pub_ds);
    delete @{$my_pub_update}{
        grep {!$valid_ds_fields{$_}} keys %$my_pub_update
    };
    $my_pub_update->{notes} = "Moo moo quack quack";
    $self->add_route_test("/api/user/datasets/$my_pub_ds_id", 'me', 'GET',    {}, {want => $my_pub_ds}, );
    $self->add_route_test("/api/user/datasets/$my_pub_ds_id", 'me', 'POST',   {}, \405, );
    $self->add_route_test("/api/user/datasets/$my_pub_ds_id", 'me', 'PUT',    $my_pub_update, \204, );
    $self->add_route_test(
        "/api/user/datasets/$my_pub_ds_id", 'me', 'DELETE', {},
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
    $self->add_route_test("/api/user/datasets/$my_priv_ds_id", 'me',  'GET',    {}, {want => $my_priv_ds},);
    $self->add_route_test("/api/user/datasets/$my_priv_ds_id", 'me',  'POST',   {}, \405,);
    $self->add_route_test("/api/user/datasets/$my_priv_ds_id", 'me',  'PUT',    $my_priv_update, \204, );
    $self->add_route_test(
        "/api/user/datasets/$my_priv_ds_id", 'me',  'DELETE', {},
        sub {
            my ($self, $msg) = @_;
            ok !($my_datasets->find({id => $my_priv_ds_id})),
                "$msg: private dataset deleted";
        },
    );

    $self->reset_fixtures();
    $self->load_fixtures('init','api');

    # other user can see own datasets, but not mine
    my $you = $self->schema->resultset('User')->find({username => 'you'});
    my $your_datasets = $you->datasets_rs;
    my @all_your_ds = map {$_->TO_JSON} $your_datasets->all;
    my $your_new_ds = ();
    $self->add_route_test('/api/user/datasets', 'you', 'GET', {}, {want => \@all_your_ds},     );
    # fixme: implement theses
    # $self->add_route_test('/api/user/datasets', 'you', 'POST',   $your_new_ds, [\302, {want => $your_new_ds}],);
    $self->add_route_test('/api/user/datasets', 'you', 'PUT', {}, \405, );
    $self->add_route_test(
        '/api/user/datasets', 'you', 'DELETE', {},
        sub {
            my ($self, $msg) = @_;
            is_deeply [$your_datasets->all], [], "$msg: all your datasets deleted";
        },
    );

    $self->reset_fixtures();
    $self->load_fixtures('init','api');

    # other user doesn't get to do anything with my datasets
    $self->add_route_forbidden("/api/user/datasets/$my_pub_ds_id", 'you', 'GET+PUT+DELETE', {},);
    $self->add_method_not_allowed("/api/user/datasets/$my_pub_ds_id",  'you', 'POST', {},);
    $self->add_route_forbidden("/api/user/datasets/$my_priv_ds_id", 'you', 'GET+PUT+DELETE', {},);
    $self->add_method_not_allowed("/api/user/datasets/$my_priv_ds_id",  'you', 'POST', {},);


    # un-authd users can't do anything with /user/dataset
    $self->add_route_needs_auth("/api/user/datasets", 'noone', 'GET+POST+DELETE', {}, );
    $self->add_method_not_allowed("/api/user/datasets", 'noone', 'PUT', {}, );
    $self->add_route_needs_auth("/api/user/datasets/$my_pub_ds_id", 'noone', 'GET+PUT+DELETE', {}, );
    $self->add_method_not_allowed("/api/user/datasets/$my_pub_ds_id", 'noone', 'POST', {}, );
    $self->add_route_needs_auth("/api/user/datasets/$my_priv_ds_id", 'noone', 'GET+PUT+DELETE', {}, );
    $self->add_method_not_allowed("/api/user/datasets/$my_priv_ds_id", 'noone', 'POST', {}, );
};


test '/user/datasets/1/columns' => sub { fail('not done'); };
test '/user/datasets/1/pages' => sub { fail('not done'); };
test '/user/datasets/1/data' => sub { fail('not done'); };
test '/user/pages' => sub { fail('not done'); };
test '/user/pages/1/columns' => sub { fail('not done'); };




test '/templates' => sub { fail('not done'); };
test '/types' => sub { fail('not done'); };
test '/sitelinker' => sub { fail('not done'); };
test '/lookup' => sub { fail('not done'); };



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
    return $users eq '*' ? @{ $self->my_users }
        : do { $self->add_my_user($users); ($users); };
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
sub add_route_needs_auth   { shift->add_route_test(@_, \401); }
sub add_route_forbidden    { shift->add_route_test(@_, \403); }
sub add_route_not_found    { shift->add_route_test(@_, \404); }
sub add_method_not_allowed { shift->add_route_test(@_, \405); }
sub add_route_readonly     { shift->add_route_test(@_, 'POST+PUT+DELETE', {}, \405); }

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

    # $self->run_responses(
    #     \@responses,
    #     sub {
    #         my ($self, $route, $response) = @_;

    #         $self->get_route($route);
    #         $self->response_for_route_is($thing);

    #         for my $method ($self->non_get_methods) {
    #             $self->method_not_allowed($method, $route);
    #         }
    #     }
    # );
