package Judoon::Schema::Role::ResultSet::HasPermissions;

use Moo::Role;

=pod

=encoding utf8

=head2 public

Filter down to public records

=cut

sub public {
    my ($self) = @_;
    return $self->search({$self->me . 'permission' => 'public'});
}


=head2 private

Filter down to private records

=cut

sub private {
    my ($self) = @_;
    return $self->search({$self->me . 'permission' => 'private'});
}


1;
__END__
