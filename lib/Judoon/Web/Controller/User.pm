package Judoon::Web::Controller::User;

=pod

=for stopwords user-centric

=encoding utf8

=head1 NAME

Judoon::Web::Controller::User - basic user identity validation

=cut

use Moose;
use namespace::autoclean;

BEGIN { extends 'Judoon::Web::Controller'; }


=head1 ACTIONS

=head2 base

Base action for managing user pages.  Currently does nothing.

=cut

sub base : Chained('/base') PathPart('user') CaptureArgs(0) {}


=head2 list

Nothing useful here, redirect elsewhere

=cut

sub list : Chained('base') PathPart('') Args(0) {
    my ($self, $c) = @_;

    if (my $user = $c->user) {
        $self->go_here($c, '/jsapp/user_view', [$user->get('username')]);
    }
    else {
        $self->go_here($c, '/login/login');
    }
}


=head2 id

Pull out the username from the url and search for that user.

=cut

sub id : Chained('base') PathPart('') CaptureArgs(1) {
    my ($self, $c, $username) = @_;
    my $user = $c->model('User::User')->find({username => $username});
    if (not $user) {
        $c->forward('/default');
        $c->detach;
    }

    if ($c->user && $c->user->username eq $user->username) {
        $c->stash->{user}{is_owner} = 1;
    }

    $c->stash->{user}{id}     = $username;
    $c->stash->{user}{object} = $user;
}


__PACKAGE__->meta->make_immutable;

1;
__END__
