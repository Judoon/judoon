package Judoon::Schema::ResultSet::DatasetColumn;

=pod

=encoding utf8

=head1 NAME

Judoon::Schema::ResultSet::DatasetColumn

=cut

use Moo;
extends 'Judoon::Schema::ResultSet';

__PACKAGE__->load_components('+DBIx::Class::Helper::ResultSet::Lookup');


=head1 METHODS

=head2 for_dataset( $dataset_id )

Filter C<DatasetColumn> to those belonging to a particular C<Dataset>.

=cut

sub for_dataset {
    my ($self, $dataset) = @_;
    return $self->search_rs({dataset_id => $dataset->id},{order_by => {-asc => 'sort'}});
}


sub with_lookups {
    my ($self) = @_;
    return $self->search_rs({}, {prefetch => ['data_type_rel', 'accession_type_rel']},);
}

1;
