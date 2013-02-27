package Judoon::Schema::ResultSet::Page;

=pod

=encoding utf8

=head1 NAME

Judoon::Schema::ResultSet::Page

=cut

use Moo;
extends 'Judoon::Schema::ResultSet';
with 'Judoon::Schema::Role::ResultSet::HasPermissions';


=head1 METHODS

=head2 ordered

Order a set of pages by their creation timestamp

=cut

sub ordered {
    my ($self) = @_;
    return $self->search_rs(
        undef,
        {order_by => {-asc => $self->me . 'created'},},
    );
}


=head2 for_dataset( $dataset )

Filter C<Page>s to those belonging to a particular C<Dataset>.

=cut

sub for_dataset {
    my ($self, $dataset) = @_;
    return $self->search_rs({dataset_id => $dataset->id});
}


1;
