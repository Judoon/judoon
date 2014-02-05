package Judoon::Web::Controller::Role::PublicDirectory;

=pod

=encoding utf8

=head1 NAME

Judoon::Web::ControllerBase::Public - base class for public search actions

=head1 DESCRIPTION

=cut

use Moose::Role;
use MooseX::MethodAttributes::Role;
use namespace::autoclean;

=head1 REQUIRES

=head2 populate_stash($c, $object)

Consuming classes must provide this method that takes in an object and
sets the relevant stash keys for the view.

=cut

requires 'populate_stash';


=head1 CONFIG

=head2 B<C<resultset_class>>

=head2 B<C<stash_key>>

=head2 B<C<template_dir>>

=cut

has resultset_class => (is  => 'ro',            );
has stash_key       => (is => 'ro', isa => 'Str');
has template_dir    => (is => 'ro', isa => 'Str');


=head1 ACTIONS

=head2 base / list / view

Basic actions for a Public Directory. All requests pass through
C<base>.  C<list> gets the list of public resources and sets the list
template. C<view> fetches the requested object and fills in the stash
data. All of these actions call a private method to do the real work,
to simplify overriding.

=cut

sub base : Chained('fixme') PathPart('fixme') CaptureArgs(0) {
    shift->private_base(@_);
}
sub list : Chained('base') PathPart('') Args() {
    shift->private_list(@_);
}
sub view : Chained('base') PathPart('') Args(1) {
    shift->private_view(@_);
}


=head1 METHODS

=head2 private_base

Empty method, just here to be overridden.

=cut

sub private_base {
    my ($self, $c) = @_;
    $c->stash->{public_rs} = $c->model($self->resultset_class)->public;
    return;

}


=head2 private_list

List all public entities and entities owned by the logged-in user.

=cut

sub private_list {
    my ($self, $c) = @_;

    my $public_rs = $c->stash->{public_rs}->with_columns->with_owner;
    my $params    = $c->req->params;
    if (my $owner = $params->{owner}) {
        $public_rs = $public_rs->owned_by($owner);
    }

    my @public_objects = $public_rs->hri->all;
    for my $obj (@public_objects) {
        $obj->{view_url} = $c->uri_for_action(
            $c->controller->action_for('view'), $obj->{id}
        );
    }
    $c->stash->{$self->stash_key}{list} = \@public_objects;
    $c->stash->{template} = $self->template_dir . '/list.tt2';
}


=head2 private_view

Display a particular Dataset or Page.

=cut

sub private_view {
    my ($self, $c, $id) = @_;

    my $object = $c->stash->{public_rs}->with_columns->with_owner->find({id => $id});
    if (not $object) {
        $c->forward('/default');
        $c->detach();
    }

    $c->stash->{$self->stash_key} = {id => $id, object => $object->TO_JSON};
    $self->populate_stash($c, $object);
    $c->stash->{template} = $self->template_dir . '/view.tt2';
}



1;
__END__

=head1 AUTHOR

Fitz ELLIOTT <felliott@fiskur.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by the Rector and Visitors of the
University of Virginia.

This is free software, licensed under:

 The Artistic License 2.0 (GPL Compatible)

=cut
