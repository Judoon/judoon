package Judoon::Web::Controller::JsApp;

use Moose;
use namespace::autoclean;

BEGIN { extends 'Judoon::Web::Controller'; }

sub base : Chained('/user/id') PathPart('') CaptureArgs(0) {
    my ($self, $c) = @_;
    $c->stash->{template} = 'jsapp/jsapp.tt2';
}


sub user_view : Chained('base') PathPart('') Args(0) {}


sub dataset_view : Chained('base') PathPart('dataset') Args(1) {
    my ($self, $c, $ds_id) = @_;

    my $dataset = $c->stash->{user}{object}->datasets_rs->find({id => $ds_id});
    if (not $dataset) {
        $c->forward('/default');
        $c->detach();
    }

    if (not $c->stash->{user}{is_owner}) {
        $self->go_here(
            $c, '/private/dataset/object',
            [$c->stash->{user}{id}, $ds_id],
        );
        $c->detach();
    }
}


sub page_view : Chained('base') PathPart('page') Args(1) {
    my ($self, $c, $page_id) = @_;

    my $page = $c->stash->{user}{object}->my_pages->find({id => $page_id});
    if (not $page) {
        $c->forward('/default');
        $c->detach();
    }

    if (not $c->stash->{user}{is_owner}) {
        $self->go_here(
            $c, '/private/page/object',
            [$c->stash->{user}{id}, $page->dataset_id, $page->id],
        );
        $c->detach();
    }
}


1;
__END__

=pod

=encoding utf8

=head1 NAME

Judoon::Web::Controller::JsApp - Dispatcher to our javascript app pages

=head1 DESCRIPTION

This controller dispatches to our javascript-based application pages.
As a result, it doesn't do much except basic access control.

=head1 ACTIONS

=head2 base

Sets the template, AngularJS takes care of the rest.

=head2 user_view

Does nothing right now.

=head2 dataset_view

Extract the L<Judoon::Schema::Result::Dataset> id and check to make sure
requesting user has valid permissions to access it.

=head2 page_view

Extract the L<Judoon::Schema::Result::Page> id and check to make sure
requesting user has valid permissions to access it.


=cut
