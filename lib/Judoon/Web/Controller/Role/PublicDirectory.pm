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


=head1 CONFIG

=head2 B<C<resultset_class>>

=head2 B<C<stash_key>>

=head2 B<C<template_dir>>

=cut

has resultset_class => (is  => 'ro',            );
has stash_key       => (is => 'ro', isa => 'Str');
has template_dir    => (is => 'ro', isa => 'Str');


=head1 ACTIONS

=head2 base / list

Basic actions for a Public Directory. All requests pass through
C<base>.  C<list> gets the list of public resources and sets the list
template.  All of these actions call a private method to do the real
work, to simplify overriding.

=cut

sub base : Chained('fixme') PathPart('fixme') CaptureArgs(0) {
    shift->private_base(@_);
}
sub list : Chained('base') PathPart('') Args() {
    shift->private_list(@_);
}


=head1 METHODS

=head2 C<B<private_base>>

Empty method, just here to be overridden.

=cut

sub private_base {}


=head2 C<B<private_list>>

List all public entities.

=cut

sub private_list {
    my ($self, $c) = @_;
    my @public_objects = $c->model($self->resultset_class)->public()->all;
    $c->stash->{$self->stash_key}{list} = \@public_objects;
    $c->stash->{template} = $self->template_dir . '/list.tt2';
}


1;
__END__
