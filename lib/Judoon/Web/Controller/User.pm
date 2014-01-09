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

use HTTP::Headers::ActionPack::LinkHeader;


=head1 ACTIONS

=head2 base

Base action for managing user pages.  Currently does nothing.

=cut

sub base : Chained('/base') PathPart('users') CaptureArgs(0) {}


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

    unless ($c->user && $c->user->username eq $user->username) {
        $self->go_here($c, '/page/list', [], {owner => $username});
        $c->detach();
    }

    $c->stash->{user}{is_owner} = 1;
    $c->stash->{user}{id}       = $username;
    $c->stash->{user}{object}   = $user;
}


=head2 new_dataset

Hopefully temporary function to handle upload of new datasets though
the web interface.  Forwards to /api/user/datasets, then redispatches
based on the response code.

=cut

sub new_dataset : Chained('/base') PathPart('user/datasets') Args(0) {
    my ($self, $c) = @_;

    my $user = $c->user;
    if (not $user) {
        $self->go_here($c, '/login/login');
        $c->deatch();
    }

    $c->stash->{authd_user} = $user->get_object;
    $c->forward('/api/wm/authd_user_datasets', [$user->username]);

    my $status = $c->res->status;
    if ($status == 201) {
        my $link = HTTP::Headers::ActionPack::LinkHeader->new_from_string(
            $c->res->header('Link')
        );
        my ($page_id) = ($link->href =~ m/(\d+)$/);

        $self->go_here(
            $c, '/jsapp/page_view', [$user->username, $page_id],
            {welcome => 1},
        );
        $c->detach();
    }
    elsif ($status == 422) {
        my $msg = $c->res->body;
        $msg =~ s/422 Unprocessable Entity\s*//;
        $self->set_error($c, $msg);
        $self->go_here($c, '/jsapp/user_view', [$user->username],);
        $c->detach();
    }
    else {
        $c->detach('/error');
    }


}


__PACKAGE__->meta->make_immutable;

1;
__END__
