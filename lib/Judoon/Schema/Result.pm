package Judoon::Schema::Result;

=pod

=encoding utf8

=head1 NAME

Judoon::Schema::Result

=head1 DESCRIPTION

Base class for C<Judoon::Schema::Result::*> classes. A convenient
place to set defaults.

=cut

use strict;
use warnings;
use 5.10.1;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components(qw{
   Helper::Row::Lookup
   InflateColumn::DateTime
   TimeStamp
   DynamicDefault
   Helper::Row::NumifyGet
   Helper::Row::RelationshipDWIM
   Helper::Row::ToJSON
});


=head1 METHODS

=head2 default_result_namespace()

The default namespace for our result classes.  Used by
L<DBIx::Class::Helpers::RelationshipDWIM>.

=cut

sub default_result_namespace { 'Judoon::Schema::Result'; }



1;

=head1 AUTHOR

Fitz ELLIOTT <felliott@fiskur.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by the Rector and Visitors of the
University of Virginia.

This is free software, licensed under:

 The Artistic License 2.0 (GPL Compatible)

=cut
