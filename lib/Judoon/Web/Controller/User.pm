package Judoon::Web::Controller::User;

use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }


sub signup : Chained('/base') PathPart('signup') Args(0) {
    my ($self, $c) = @_;
    $c->stash->{template} = 'signup.tt2';
}

sub signup_do : Chained('/base') PathPart('signup_do') Args(0) {
    my ($self, $c) = @_;

    my $params = $c->req->params;
    my %user_params = map {my $k = $_; $k=~ s/^user\.//; $k => $params->{$_}}
        grep {m/^user\./} keys %$params;

    if ($user_params{password} ne $user_params{confirm_password}) {
        $c->log->debug("PASS MATCH ERROR!");
        $c->flash->{error} = 'Passwords do not match!';
        $c->res->redirect($c->uri_for_action('/user/signup'));
        $c->detach;
    }

    my $user;
    eval {
        $user = $c->model('User::User')->create_user(\%user_params);
    };
    if ($@) {
        $c->log->debug("USER ADD ERROR! $@");
        $c->flash->{error} = $@;
        $c->res->redirect($c->uri_for_action('/user/signup'));
        $c->detach;
    };

    # fixme: need to login use here

    $c->res->redirect($c->uri_for_action('/user/edit', [$user->username]));
    $c->detach;
}


sub base : Chained('/edit') PathPart('user') CaptureArgs(0) {}
sub id   : Chained('base')  PathPart('id')   CaptureArgs(1) {
    my ($self, $c, $username) = @_;
    my $user = $c->model('User::User')->find({username => $username});
    if (not $user) {
        $c->forward('error');
    }

    if ($user->username ne $c->user->username) {
        $c->forward('denied');
    }

    $c->stash->{user}{id}     = $username;
    $c->stash->{user}{object} = $user;
}
sub edit : Chained('id') PathPart('') Args(0) {
    my ($self, $c) = @_;
    $c->stash->{template} = 'user/edit.tt2';
    $c->stash->{datasets} = [$c->stash->{user}{object}->datasets()];
}
sub edit_do : Chained('id') PathPart('edit_do') Args(0) {
    my ($self, $c) = @_;


}




__PACKAGE__->meta->make_immutable;

1;
__END__
