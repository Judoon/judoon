package Judoon::Schema;

=pod

=encoding utf8

=head1 NAME

Judoon::Schema

=cut

use 5.10.1;

use Moo;
extends 'DBIx::Class::Schema';


=head2 C<$VERSION>

C<$VERSION> is very important for the DBIx::Class::Migration scripts
to work

=cut

our $VERSION = 11;


__PACKAGE__->load_namespaces;


1;
