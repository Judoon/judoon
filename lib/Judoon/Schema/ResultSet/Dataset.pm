package Judoon::Schema::ResultSet::Dataset;

=pod

=encoding utf8

=head1 NAME

Judoon::Schema::ResultSet::Dataset

=cut

use Moo;
extends 'Judoon::Schema::ResultSet';
with 'Judoon::Schema::Role::ResultSet::HasPermissions';


=head1 METHODS

=head2 ordered

Order a set of datasets by their creation timestamp

=cut

sub ordered {
    my ($self) = @_;
    return $self->search_rs(
        undef,
        {order_by => {-asc => $self->me . 'created'},},
    );
}


=head2 with_pages()

Add prefetch of pages to current rs

=cut

sub with_pages {
    return shift->search_rs(
        {},
        {prefetch => 'pages', order_by => 'pages.created'}
    );
}


1;
