package Judoon::Web::Controller::JsApp;

use Moose;
use namespace::autoclean;

BEGIN { extends 'Judoon::Web::Controller'; }

sub base : Chained('/user/id') PathPart('') CaptureArgs(0) {
    my ($self, $c) = @_;
    $c->stash->{template} = 'jsapp/jsapp.tt2';
}


sub user_view : Chained('base') PathPart('') Args(0) {}


sub dataset_list : Chained('base') PathPart('datasets') Args(0) {
    my ($self, $c) = @_;
    $self->go_here($c, '/jsapp/user_view');
    $c->detach();
}
sub dataset_view : Chained('base') PathPart('datasets') Args(1) {
    my ($self, $c, $ds_id) = @_;

    my $dataset = $c->stash->{user}{object}->datasets_rs->find({id => $ds_id});
    if (not $dataset) {
        $c->forward('/default');
        $c->detach();
    }

    if (not $c->stash->{user}{is_owner}) {
        $self->go_here($c, '/dataset/view', [$ds_id]);
        $c->detach();
    }
}


sub page_list : Chained('base') PathPart('views') Args(0) {
    my ($self, $c) = @_;
    $self->go_here($c, '/jsapp/user_view');
    $c->detach();
}
sub page_view : Chained('base') PathPart('views') Args(1) {
    my ($self, $c, $page_id) = @_;

    my $page = $c->stash->{user}{object}->my_pages->find({id => $page_id});
    if (not $page) {
        $c->forward('/default');
        $c->detach();
    }

    if (not $c->stash->{user}{is_owner}) {
        $self->go_here($c, '/page/view', [$page->id]);
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

=head2 dataset_list

Redirects user to their overview page.

=head2 dataset_view

Extract the L<Judoon::Schema::Result::Dataset> id and check to make sure
requesting user has valid permissions to access it.

=head2 page_list

Redirects user to their overview page.

=head2 page_view

Extract the L<Judoon::Schema::Result::Page> id and check to make sure
requesting user has valid permissions to access it.

=head1 AUTHOR

Fitz ELLIOTT <felliott@fiskur.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by the Rector and Visitors of the
University of Virginia.

This is free software, licensed under:

 The Artistic License 2.0 (GPL Compatible)

=cut
