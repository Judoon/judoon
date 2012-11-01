package Judoon::Schema::ResultSet::DatasetColumn;

=pod

=encoding utf8

=cut

use Moo;
use feature ':5.10';
extends 'DBIx::Class::ResultSet';


=head2 B<C<for_dataset( $dataset_id )>>

Filter C<DatasetColumn> to those belonging to a particular C<Dataset>.

=cut

sub for_dataset {
    my ($self, $dataset) = @_;
    return $self->search_rs({dataset_id => $dataset->id},{order_by => {-asc => 'sort'}});
}

1;
__END__
