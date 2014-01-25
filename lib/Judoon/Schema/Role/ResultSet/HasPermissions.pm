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

=head1 AUTHOR

Fitz ELLIOTT <felliott@fiskur.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by the Rector and Visitors of the
University of Virginia.

This is free software, licensed under:

 The Artistic License 2.0 (GPL Compatible)

=cut
