package t::Role::API;

=pod

=encoding utf-8

=head1 NAME

t::Role::API - a role for testing the Judoon API

=head1 DESCRIPTION

The purpose of this role is to abstract out common methods for testing
our API and to provide tracking of tested permutations of route, user,
and method.

This module keeps track of routes that have been tested, the user who
was logged in at the time of the test, and the HTTP verb (method)
called on the API endpoint.  At the end of the tests, the script can
call C<report_untested_routes()> to generate a table of
routes/user/method combinations that were not tested.  'Tested' in
this case refers to tests run through the add_route_test() method or
its related helper functions.

=cut

use HTTP::Request::Common qw(GET POST PUT DELETE);
use List::AllUtils ();
use MooX::Types::MooseLike::Base qw(ArrayRef HashRef);
use Text::Table;

use Test::Roo::Role;

requires 'mech';
requires 'encode_json';
requires 'decode_json';


=head1 ATTRIBUTES / METHODS

=head2 api_debug

A flag for turning on extra debugging.  Writable so it can be turned
on and off where desired.

=cut

has api_debug => (is => 'rw', default => 0,);


=head2 api_routes / _build_api_routes

An C<ArrayRef> of API routes that have appeared in at least one test
so far.

=head3 add_api_route( $route )

Add a route to the C<api_routes> list if it hasn't yet been seen.

=cut

has api_routes  => (is => 'lazy', isa => ArrayRef,);
sub _build_api_routes { return []; }
sub add_api_route {
    my ($self, $route) = @_;
    my @routes = @{ $self->api_routes };
    if (List::AllUtils::all {$route ne $_} @routes) {
        push @{ $self->api_routes }, $route;
    }
}


=head2 api_users / _build_api_users

An C<ArrayRef> of API users that have appeared in at least one test so
far. Default is C<me>, C<you>, and C<noone>.  C<noone> is treated
specially by later code to skip login/logout.

=head3 add_api_user( $user )

Add a user to the C<api_users> list if they haven't yet been seen.

=head3 _expand_api_users( $user_spec )

Turn a C<$user_spec> such as C<'*'>, C<'you+noone'> into a list of
valid users.  C<'*'> returns all users currently in C<api_users>. If
C<$user_spec> contains a C<'+'>, it splits on C<'+'> and returns the
resulting list.

=cut

has api_users => (is => 'lazy', isa => ArrayRef,);
sub _build_api_users { return [qw(me you noone)]; }
sub add_api_user {
    my ($self, $user) = @_;
    my @api_users = @{ $self->api_users };
    if  (List::AllUtils::all {$_ ne $user} @api_users) {
        push @{ $self->api_users }, $user;
    }
}
sub _expand_api_users {
    my ($self, $users) = @_;
    return $users eq '*'  ? @{ $self->api_users }
        : $users =~ m/\+/ ? split(/\+/, $users)
        :                   do { $self->add_api_user($users); ($users); };
}


=head2 api_methods / _build_api_methods

An C<ArrayRef> of API methods that have appeared in at least one test so
far. Default is C<GET>, C<POST>, C<PUT>, and C<DELETE>.

=head3 add_api_method( $method )

Add a method to the C<api_methods> list if it hasn't yet been seen.

=head3 _expand_api_methods( $method_spec )

Turn a C<$method_spec> such as C<'*'>, C<'GET+POST'> into a list of
valid methods.  C<'*'> returns all methods currently in C<api_methods>. If
C<$method_spec> contains a C<'+'>, it splits on C<'+'> and returns the
resulting list.

=cut

has api_methods => (is => 'lazy', isa => ArrayRef,);
sub _build_api_methods { return [qw(GET POST PUT DELETE)]; }
sub add_api_method {
    my ($self, $method) = @_;
    my @api_methods = @{ $self->api_methods };
    if  (List::AllUtils::all {$_ ne $method} @api_methods) {
        push @{ $self->api_methods }, $method;
    }
}
sub _expand_api_methods {
    my ($self, $methods) = @_;
    return $methods eq '*'  ? @{ $self->api_methods }
        : $methods =~ m/\+/ ? split(/\+/, $methods)
        :                     do { $self->add_api_method($methods); ($methods); };
}


=head2 _api_tests / _build__api_tests

An C<ArrayRef> of API tests that have been run so far.

=head3 add_api_route( $route )

Add a route to the C<api_routes> list if it hasn't yet been seen.

=head3 api_test_id( $route, $user, $method )

Turn a list of C<$route>, C<$user>, C<$method> into a test
identifier. (IOW, C<join> them with C<,>)

=head3 seen_api_test( $route, $user, $method )

Returns true if this permutation or arguments has been tested.

=cut

has _api_tests => (is => 'lazy', isa => HashRef,);
sub _build__api_tests { return {}; }
sub api_test_id { shift; return join(',', @_); }
sub seen_api_test {
    my $self = shift;
    return exists $self->_api_tests->{ $self->api_test_id(@_) };
}
sub add_api_test {
    my $self = shift;
    $self->_api_tests->{ $self->api_test_id( @_ ) }++;
}


=head1 TEST METHOD

=head2 add_route_test( $route, $userspec, $methodspec, $object, $testspec )

This sub runs tests and adds them to the list of seen tests.

C<$route> is the API endpoint to request.

C<$userspec> is passed to C<< $self->_expand_api_users() >> to get a list of
users to log in as before running the test.  If the user is C<noone>,
no login is performed.

C<$methodspec> is passed to C<< $self->_expand_api_methods() >> to get
a list of HTTP methods to use when performing the request.

C<$object> is a perl data structure that is used as the data payload
for PUT and POST requests.  For GET and DELETE requests, pass C<{}>,
which will be silently ignored.

C<$testspec> is a ref that is passed to C<< $self->expand_test() >>
and defines one or more tests that will be run after the request is
made.  The type of test run depends on the reftype of C<$testspec>.

=head3 C<$testspec> types

=over

=item SCALAR

If C<$testspec> is a scalar reference, it is assumed to be a numerical
HTTP status code.  This will be compared to C<< $self->mech->status >>.

=item CODE

If C<$testspec> is a sub ref, the sub will be executed with C<$self>
and the default test description, C<$msg> as args.  The sub is
responsible for performing its own test.

=item HASH

If C<$testspec> is a hash ref, then it is expected to have a C<want>
key that points to a perl data structure.  This data structure will be
compared via C<is_deeply()> to the deserialized response.

=item ARRAY

If C<$testspec> is an array ref, then C<< $self->_expand_test() >>
will be called recursively for each entry in C<@$testspec>.  This
allows multiple tests to be run for one request.

=back

=cut

sub add_route_test {
    my ($self, $route, $users, $methods, $object, $test) = @_;

    $self->add_api_route($route);

    my @users = $self->_expand_api_users($users);
    my @methods = $self->_expand_api_methods($methods);

    my $test_sub = $self->_expand_test($test);
    for my $user (@users) {

        $self->login( @{$self->users->{$user}}{qw(username password)} )
            unless ($user eq 'noone');
        for my $method (@methods) {
            my $test_method = "_${method}_json";
            diag "*** $user $method $route" if ($self->api_debug);
            $self->$test_method($route, $object);
            diag "  === " . substr($self->mech->content, 0, 30) if ($self->api_debug);
            $test_sub->($self, "$user $method $route");
            $self->add_api_test($route, $user, $method);
        }
        $self->logout  unless ($user eq 'noone');

    }
}

=head1 CONVENIENCE TESTS

For simplicty, the following common tests are provided.  Note, that if
C<$object> is listed in the signature, it is required, even if it is
not used.

=head2 add_route_needs_auth( $route, $userspec, $methodspec, $object )

Response status is 401.

=head2 add_route_forbidden( $route, $userspec, $methodspec, $object )

Response status is 403.

=head2 add_route_not_found( $route, $userspec, $methodspec, $object )

Response status is 404.

=head2 add_route_bad_method( $route, $userspec, $methodspec, $object )

Response status is 405.

=head2 add_route_readonly( $route, $userspec )

Shortcut for routes where only GET requests are applicible.  Calls
C<< $self->add_route_bad_method() >>, setting C<$methodspec> to
C<'POST+PUT+DELETE> and C<$object> to C<{}>.

=head2 add_route_created( $route, $userspec, $methodspec, $object, $compare )

Calls C<< add_route_test() >> with the given parameters and a
constructed C<$testspec>.  The C<$testspec> tests for a 201 Created
response code, then extracts the created object's URL from the
Location header.  The created object is fetched and is checked to make
sure all fields in C<$compare> match the corresponding field in the
created object.

=head2 add_route_redirects( $route, $userspec, $methodspec, $object )

Turns off automatic redirection in C<< $self->mech >>, then tests the
route to make sure the response status is 302.

=cut

sub add_route_needs_auth { shift->add_route_test(@_, \401); }
sub add_route_forbidden  { shift->add_route_test(@_, \403); }
sub add_route_not_found  { shift->add_route_test(@_, \404); }
sub add_route_bad_method { shift->add_route_test(@_, \405); }
sub add_route_readonly   { shift->add_route_bad_method(@_, 'POST+PUT+DELETE', {}); }

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

# see add_route_test() for description
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


=head1 DIAGNOSTIC METHODS

=head2 report_untested_routes

Check every permutation of C<api_routes>, C<api_users>, and
C<api_methods> and display a table showing any combination that has
not been tested.

=cut

sub report_untested_routes {
    my ($self) = @_;

    my $table = Text::Table->new(qw(Route User Method Tested?));
    $table->rule('-', '+');
    my $found_untested = 0;
    for my $route (@{ $self->api_routes }) {
        for my $user (@{ $self->api_users }) {
            for my $method (@{ $self->api_methods }) {
                my $seen = $self->seen_api_test($route, $user, $method);
                if (not $seen) {
                    $found_untested = 1;
                    $table->add($route, $user, $method, 0+$seen);
                }
            }
        }
    }

    diag ($found_untested ? "Untested routes:\n" . $table->table
              :             "All route permutations tested");
}


=head1 API COMMUNICATION METHODS

Make requests of the server via JSON.

=head2 _GET_json( $url ) / _DELETE_json( $url )

Call the named HTTP method on the API endpoint at C<$url>.

=head2 _POST_json( $url, object ) / _PUT_json( $url, object )

Call the named HTTP method on the API endpoint at C<$url> with
C<$object> as the data payload. C<$object> should be a perl data
structure that can be serialized into JSON.

=cut

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
