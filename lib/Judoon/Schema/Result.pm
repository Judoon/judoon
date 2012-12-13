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
   TimeStamp
   Helper::Row::NumifyGet
   Helper::Row::ToJSON
   Helper::Row::RelationshipDWIM
   Helper::Row::JoinTable
});


1;
