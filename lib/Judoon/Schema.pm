package Judoon::Schema;

=pod

=encoding utf8

=head1 NAME

Judoon::Schema

=cut

use 5.10.1;

use Moo;
use namespace::clean;

extends 'DBIx::Class::Schema::Config';


=head2 C<$VERSION>

C<$VERSION> is very important for the DBIx::Class::Migration scripts
to work

=cut

our $VERSION = 21;


__PACKAGE__->load_namespaces;


1;

=head1 AUTHOR

Fitz ELLIOTT <felliott@fiskur.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by the Rector and Visitors of the
University of Virginia.

This is free software, licensed under:

 The Artistic License 2.0 (GPL Compatible)

=cut
