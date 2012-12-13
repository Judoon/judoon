package Judoon::Schema::ResultSet::DatasetColumn;

=pod

=encoding utf8

=head1 NAME

Judoon::Schema::ResultSet::DatasetColumn

=cut

use Moo;
extends 'Judoon::Schema::ResultSet';


=head1 METHODS

=head2 hri()

Convenience method to set the HashRefInflator result_class

=cut

sub hri {
   shift->search(undef, {
      result_class => 'DBIx::Class::ResultClass::HashRefInflator' })
}


=head2 for_dataset( $dataset_id )

Filter C<DatasetColumn> to those belonging to a particular C<Dataset>.

=cut

sub for_dataset {
    my ($self, $dataset) = @_;
    return $self->search_rs({dataset_id => $dataset->id},{order_by => {-asc => 'sort'}});
}


1;
