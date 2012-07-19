package Judoon::Web::Controller::Page;

=pod

=encoding utf8

=head1 NAME

Judoon::Web::Controller::Page - display public pages

=cut

use Moose;
use namespace::autoclean;

BEGIN { extends 'Judoon::Web::Controller'; }


=head2 base

The base action for this controller.  All actions will pass through
here

=cut

sub base : Chained('/') PathPart('page') CaptureArgs(0) {
    my ($self, $c) = @_;
}

=head2 list

List all public pages.

=cut

sub list : Chained('base') PathPart('') Args() {
    my ($self, $c) = @_;
    my @public_pages = $c->model('User::Page')->public()->all;
    $c->stash->{page}{list} = \@public_pages;
    $c->stash->{template} = 'public_page/list.tt2';
}

=head2 id

Get the id for a specific public page

=cut

sub id : Chained('base') PathPart('') CaptureArgs(1) {
    my ($self, $c, $id) = @_;

    my $page = $c->model('User::Page')->public->find({id => $id});
    if (not $page) {
        $c->flash->{alert}{error} = q{Couldn't find that page};
        $self->go_here('/page/list');
        $c->detach();
    }

    $c->stash->{page}{id} = $id;
    $c->stash->{page}{object} = $page;
}


=head2 view

Display a particular table

=cut

sub view : Chained('id') PathPart('') Args(0) {
    my ($self, $c) = @_;
    $c->stash->{template} = 'public_page/view.tt2';
}


__PACKAGE__->meta->make_immutable;

1;
__END__
