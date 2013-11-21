package Judoon::Schema::ResultSet::Dataset;

=pod

=for stopwords DBIC collapser

=encoding utf8

=head1 NAME

Judoon::Schema::ResultSet::Dataset

=cut

use Scalar::Util qw(blessed);

use Moo;
use namespace::clean;

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
        {prefetch => 'pages', order_by => {-asc => 'pages.created'}}
    );
}


=head2 ordered_with_pages_and_pagecols

Fetch a list of datasets, ordered by their creation timestamp, while
prefetching their pages and page columns.  Pages are ordered by
creation timestamp, PageColumns are ordered by their sort field.

In a future release of DBIC, we may be able to add dataset columns to
this as well.  The order_by fields are very important for the current
prefetch collapser, b/c related records must be contiguous.  This
should also be fixed in the future DBIC release.

=cut

sub ordered_with_pages_and_pagecols {
    my ($self) = @_;
    return $self->search_rs(
        undef,
        {
            prefetch => {'pages' => 'page_columns'},
            order_by => [
                {-asc => $self->me . 'created',},
                {-asc => ['pages.dataset_id', 'pages.created',],},
                {-asc => ['page_columns.page_id', 'page_columns.sort', ],},
            ],
        },
    );
}


=head2 for_user

Datasets for a particular user.

=cut

sub for_user {
    my ($self, $id_or_user) = @_;

    my $id = blessed($id_or_user) ? $id_or_user->id
           : ref($id_or_user)     ? $id_or_user->{id}
           :                        $id_or_user;
    return $self->search({user_id => $id});
}


=head2 get_our_owner

This is a fragile and not-well-tested method that retrieves the owner
from and C<ResultSet::Dataset> that could be empty and should have
only one owner.

=cut

# this method is evil.
sub get_our_owner {
    my ($self)  = @_;
    my $schema  = $self->result_source->schema;
    my $user_id = ${ $self->get_column('user_id')->as_query }->[1][1];
    return $schema->resultset('User')->find({id => $user_id});
}


=head2 with_owner

Prefetch the owner.

=cut

sub with_owner {
    my ($self) = @_;
    return $self->prefetch('user');
}


=head2 with_columns

Prefetch the subordinate columns.

=cut

sub with_columns {
    my ($self) = @_;
    return $self->prefetch('ds_columns');
}

1;
