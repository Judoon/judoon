package Judoon::Web::Controller::Login;

=pod

=encoding utf8

=head1 NAME

Judoon::Web::Controller::Login - manage user logins

=cut

use Moose;
use namespace::autoclean;

BEGIN { extends 'Judoon::Web::Controller'; }

with 'Judoon::Web::Controller::Role::GoHere';

=head1 DESCRIPTION

=head2 Actions

=head3 C<B<not_required>>

C<not_required> is a no-op chaining point for actions that do not
require a login.

=cut

sub not_required : Chained('/') PathPart('') CaptureArgs(0) {}


=head3 C<B<required>>

C<required> is a chaining point for actions that require a user to be
logged in.  If they are not, they will be sent to the login page, and
their intended URL saved.  After login, they will be sent to the URL.

=cut

sub required : Chained('/') PathPart('') CaptureArgs(0) {
    my ($self, $c) = @_;
    if (!$c->user) {
        my $message = 'You need to login to view this page!';
        $self->login_redirect($c, $message);
        $c->detach;
    }
}


=head3 C<B<login>>

Action for logging in. GET requests show the login page, POST requests
attempt a login. Dispatches to C<L</login_GET>> for GETs,
C<L</login_POST>> for POSTs.

If an already logged-in user hits this action again, they are sent to
their overview.


=cut

sub login :Chained('not_required') :PathPart('login') :Args(0) ActionClass('REST') {
    my ($self, $c) = @_;
    if ($c->user) {
        $self->go_here($c, '/user/edit', [$c->user->username]);
        $c->detach;
    }
    $c->stash->{template} = 'login/login.tt2';
}


=head3 C<B<logout>>

Action for logging out users.  Returns to index.

=cut

sub logout : Chained('/') PathPart('logout') Args(0) {
    my ($self, $c) = @_;
    $c->logout;
    $c->delete_session;
    $c->res->redirect($c->uri_for('/'));
}


=head2 Other methods

=head3 C<B<login_GET>>

Placeholder method. C<L</login>> does all the necessary work.

=cut

sub login_GET {}


=head3 C<B<login_POST>>

Attepts to login the user with the supplied credentials.  If
successful, redirects to the user's overview or the previously
attempted url.  If unsuccessful, displays an error message.

=cut

sub login_POST {
    my ($self, $c) = @_;

    my $p = $c->req->parameters;
    if ( $c->authenticate({username => $p->{username}, password => $p->{password}}) ) {
        $c->res->redirect($self->redirect_after_login_uri($c));
        $c->extend_session_expires(999999999999)
            if $p->{remember};
    }
    else {
        $c->stash->{alert}{error} = 'Username or password is incorrect.';
    }
}


=head3 B<C<login_redirect>>

C<login_redirect> saves the requested url and redirects to the login
page.

=cut

sub login_redirect {
    my ($self, $c, $message) = @_;
    $c->flash->{alert}{error} = $message;
    $c->session->{redirect_to_after_login} = $c->req->uri->as_string;
    $c->response->redirect($c->uri_for($self->action_for("login")));
    $c->detach;
}


=head3 C<B<redirect_after_login_uri>>

Returns the saved url if user was attempting to get to a protected
page. Otherwise, sends user to their overview.

=cut

sub redirect_after_login_uri {
    my ($self, $c) = @_;
    return $c->session->{redirect_to_after_login}
        ? delete $c->session->{redirect_to_after_login}
        : $c->uri_for_action('/user/edit', [$c->user->username]);
}


__PACKAGE__->meta->make_immutable;

1;
__END__
