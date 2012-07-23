package Judoon::DB::User::Schema::ResultSet::DatasetColumn;

=pod

=encoding utf8

=cut

use Moo;
use feature ':5.10';
extends 'DBIx::Class::ResultSet';


=head2 B<C<ordinal_position_for>>

Get the ordinal position for a particular C<DatasetColumn> among the
others in its C<Dataset>.

=cut

sub ordinal_position_for {
    my ($self, $ds_id, $sort) = @_;
    return $self->search_rs(
        {dataset_id => $ds_id, 'sort' => {'<' => $sort}}
     )->count + 1;
}


1;
__END__
