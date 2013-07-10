package Judoon::Schema::Candy;

use Moo;
extends 'DBIx::Class::Candy';

sub base { 'Judoon::Schema::Result' }


1;
__END__

=pod

=encoding utf8

=head1 NAME

Judoon::Schema::Candy - import DBIx::Class::Candy syntax

=head1 DESCRIPTION

L</DBIx::Class::Candy> is a handy module that lets us defined our
Result classes with much more compact syntax.

=head1 Methods

=head2 base

Set the base Result class for our Results to
L<Judoon::Schema::Result>.

=cut
