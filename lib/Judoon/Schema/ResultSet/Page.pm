package Judoon::Schema::ResultSet::Page;

=pod

=encoding utf8

=head1 NAME

Judoon::Schema::ResultSet::Page

=cut

use Scalar::Util qw(blessed);

use Moo;
use namespace::clean;

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


=head2 for_user

Pages for a particular user.

=cut

sub for_user {
    my ($self, $id_or_user) = @_;

    my $id = blessed($id_or_user) ? $id_or_user->id
           : ref($id_or_user)     ? $id_or_user->{id}
           :                        $id_or_user;
    return $self->search(
        {'dataset.user_id' => $id},
        {join => 'dataset'},
    );
}


=head2 with_owner

Prefetch the owner.

=cut

sub with_owner {
    my ($self) = @_;
    return $self->prefetch({dataset => 'user'});
}


=head2 with_columns

Prefetch the subordinate columns.

=cut

sub with_columns {
    my ($self) = @_;
    return $self->prefetch('page_columns');
}


=head2 owned_by( $username )

Pages for a particular user.

=cut

sub owned_by {
    my ($self, $username) = @_;
    return $self->search(
        {'user.username' => $username},
        {join => {'dataset' => 'user'}},
    );
}


1;

=head1 AUTHOR

Fitz ELLIOTT <felliott@fiskur.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by the Rector and Visitors of the
University of Virginia.

This is free software, licensed under:

 The Artistic License 2.0 (GPL Compatible)

=cut
