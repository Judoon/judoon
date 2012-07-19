package Judoon::Web::Controller::Login;

=pod

=encoding utf8

=head1 NAME

Judoon::Web::Controller::Login - manage user logins

=cut

use Moose;
use namespace::autoclean;

BEGIN { extends 'Judoon::Web::Controller'; }


sub not_required : Chained('/') PathPart('') CaptureArgs(0) {}
sub required     : Chained('/') PathPart('') CaptureArgs(0) {
    my ($self, $c) = @_;
    if (!$c->user) {
        my $message = 'You need to login to view this page!';
        $c->controller('Login')->login_redirect($c, $message);
        $c->detach;
    }
}


sub login :Chained('not_required') :PathPart('login') :Args(0) ActionClass('REST') {
    my ($self, $ctx) = @_;
    $ctx->stash->{template} = 'login/login.tt2';
}

sub login_GET {}

sub login_POST {
    my ($self, $c) = @_;

    my $p = $c->req->parameters;
    if ( $c->authenticate({username => $p->{username}, password => $p->{password}}) ) {
        $self->do_post_login_redirect($c);
        $c->extend_session_expires(999999999999)
            if $p->{remember};
    }
    else {
        $c->stash->{alert}{error} = 'Username or password is incorrect.';
    }
}

sub do_post_login_redirect {
    my ($self, $c) = @_;
    $c->res->redirect($self->redirect_after_login_uri($c));
}

sub login_redirect {
    my ($self, $c, $message) = @_;
    $c->flash->{alert}{error} = $message;
    $c->session->{redirect_to_after_login} = $c->req->uri->as_string;
    $c->response->redirect($c->uri_for($self->action_for("login")));
    $c->detach;
}

sub redirect_after_login_uri {
    my ($self, $c) = @_;

    return $c->session->{redirect_to_after_login}
        ? delete $c->session->{redirect_to_after_login}
        : $c->uri_for_action('/user/edit', [$c->user->username]);
}


sub logout : Chained('/') PathPart('logout') Args(0) {
    my ($self, $c) = @_;
    $c->logout;
    $c->delete_session;
    $c->res->redirect($c->uri_for('/'));
}


__PACKAGE__->meta->make_immutable;

1;
__END__
