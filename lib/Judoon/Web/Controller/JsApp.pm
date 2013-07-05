package Judoon::Web::Controller::JsApp;

use Moose;
use namespace::autoclean;

BEGIN { extends 'Judoon::Web::Controller'; }

sub base : Chained('/user/id') PathPart('') CaptureArgs(0) {}

sub page_id : Chained('base') PathPart('page') CaptureArgs(1) {
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

    $c->stash->{page}{object} = $page;
}

sub page_view : Chained('page_id') PathPart('') Args(0) {
    my ($self, $c) = @_;
    $c->stash->{template} = 'jsapp/page.tt2';
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

Base action, currently does nothing.

=head2 page_id

Extract the L<Judoon::Schema::Result::Page> id, checks to make sure
requesting user has valid permissions to access it.

=head2 page_view

Sets the template, AngularJS takes care of the rest.

=cut
