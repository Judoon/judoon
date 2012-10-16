use utf8;
package Judoon::DB::User::Schema;

=pod

=encoding utf8

=head1 NAME

Judoon::DB::User::Schema

=cut

use Moo;
extends 'DBIx::Class::Schema';

__PACKAGE__->load_namespaces;


=head2 C<$VERSION>

C<$VERSION> is very important for the DBIx::Class::Migration scripts
to work

=cut

our $VERSION = 7;

1;
