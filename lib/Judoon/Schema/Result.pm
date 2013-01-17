package Judoon::Schema::Result;

=pod

=encoding utf8

=head1 NAME

Judoon::Schema::Result

=head1 DESCRIPTION

Base class for C<Judoon::Schema::Result::*> classes. A convenient
place to set defaults.

=cut

use 5.10.1;

use Moo;
extends 'DBIx::Class::Core';

__PACKAGE__->load_components(qw{
   +DBIx::Class::Relationship::LookupProxy
   InflateColumn::DateTime
   TimeStamp
   Helper::Row::NumifyGet
   Helper::Row::RelationshipDWIM
});


=head1 METHODS

=head2 default_result_namespace()

The default namespace for our result classes.  Used by
L<DBIx::Class::Helpers::RelationshipDWIM>.

=cut

sub default_result_namespace { 'Judoon::Schema::Result'; }



1;
