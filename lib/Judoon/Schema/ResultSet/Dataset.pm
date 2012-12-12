package Judoon::Schema::ResultSet::Dataset;

=pod

=encoding utf8

=head1 NAME

Judoon::Schema::ResultSet::Datset

=head1 DESCRIPTION

Custom ResultSet class for Datasets

=cut

use Moo;
use feature ':5.10';
extends 'DBIx::Class::ResultSet';
with 'Judoon::Schema::Role::ResultSet::HasPermissions';

=head1 METHODS

=head2 hri

Convenience method to set the HashRefInflator result_class

=cut

sub hri {
   shift->search(undef, {
      result_class => 'DBIx::Class::ResultClass::HashRefInflator' })
}


=head2 with_pages()

Add prefetch of pages to current rs

=cut

sub with_pages { return shift->search_rs({}, {prefetch => 'pages'}); }

#sub ordered { return shift->search({}, {order_by => {-asc => 'name'}}); }


1;
__END__
