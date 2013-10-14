package t::Role::API;

use HTTP::Request::Common qw(GET POST PUT DELETE);
use List::AllUtils ();
use MooX::Types::MooseLike::Base qw(ArrayRef HashRef);
use Text::Table;

use Test::Roo::Role;

requires 'mech';

has routes   => (is => 'lazy', isa => ArrayRef,);
has my_users => (is => 'lazy', isa => ArrayRef,);
has methods  => (is => 'lazy', isa => ArrayRef,);
has _tests   => (is => 'lazy', isa => HashRef,);
has debug    => (is => 'rw', default => 0,);


# HELPER METHODS

sub _build_routes { return []; }
sub add_route {
    my ($self, $route) = @_;
    my @routes = @{ $self->routes };
    if (List::AllUtils::all {$route ne $_} @routes) {
        push @{ $self->routes }, $route;
    }
}


sub _build_my_users { return [qw(me you noone)]; }
sub add_my_user {
    my ($self, $user) = @_;
    my @my_users = @{ $self->my_users };
    if  (! List::AllUtils::any {$_ eq $user} @my_users) {
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
    if  (! List::AllUtils::any {$_ eq $method} @methods) {
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

        $self->login( @{$self->users->{$user}}{qw(username password)} )
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


sub report_untested_routes {
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





1;
__END__
