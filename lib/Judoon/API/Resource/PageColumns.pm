package Judoon::API::Resource::PageColumns;

use Judoon::Tmpl;

use Moo;
use namespace::clean;

extends 'Judoon::API::Resource';
with 'Judoon::Role::JsonEncoder';
with 'Judoon::API::Resource::Role::Set';


around create_resource => sub {
    my $orig = shift;
    my $self = shift;
    my $data = shift;

    my $jstmpl = $data->{template};
    my $tmpl   = Judoon::Tmpl->new_from_jstmpl($jstmpl);
    $data->{template} = $tmpl;
    return $self->$orig($data);
};


1;
__END__

=pod

=encoding utf8

=head1 NAME

Judoon::API::Resource::PageColumns - An set of PageColumns

=head1 DESCRIPTION

See L</Web::Machine::Resource>.

=head1 METHODS

=head2 create_resource

Translate the C<template> parameter into a L<Judoon::Tmpl> object
suitable for insertion into the database.

=cut
