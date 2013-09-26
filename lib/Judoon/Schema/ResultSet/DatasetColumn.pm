package Judoon::Schema::ResultSet::DatasetColumn;

=pod

=encoding utf8

=head1 NAME

Judoon::Schema::ResultSet::DatasetColumn

=cut

use Moo;
use namespace::clean;

extends 'Judoon::Schema::ResultSet';

__PACKAGE__->load_components('+DBIx::Class::Helper::ResultSet::Lookup');


=head1 METHODS

=head2 for_dataset( $dataset ) / for_dataset_id( $dataset_id )

Filter C<DatasetColumn> to those belonging to a particular
C<Dataset>. C<for_dataset> takes a C<Dataset> row object, and
C<for_dataset_id> takes a C<Dataset>'s C<id>.

=cut

sub for_dataset { return $_[0]->for_dataset_id($_[1]->id); }

sub for_dataset_id {
    my ($self, $dataset_id) = @_;
    return $self->search_rs(
        { dataset_id => $dataset_id },
        { order_by => {-asc => $self->me . 'sort'} });
}

1;
