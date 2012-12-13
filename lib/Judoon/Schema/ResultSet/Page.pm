package Judoon::Schema::ResultSet::Page;

=pod

=encoding utf8

=head1 NAME

Judoon::Schema::ResultSet::Page

=head1 DESCRIPTION

Custom ResultSet class for Pages

=cut

use Moo;
extends 'Judoon::Schema::ResultSet';
with 'Judoon::Schema::Role::ResultSet::HasPermissions';

=head1 METHODS

=head2 hri

Convenience method to set the HashRefInflator result_class

=cut

sub hri {
   shift->search(undef, {
      result_class => 'DBIx::Class::ResultClass::HashRefInflator' })
}


=head2 B<C<for_dataset( $dataset )>>

Filter C<Page>s to those belonging to a particular C<Dataset>.

=cut

sub for_dataset {
    my ($self, $dataset) = @_;
    return $self->search_rs({dataset_id => $dataset->id});
}

1;
__END__
