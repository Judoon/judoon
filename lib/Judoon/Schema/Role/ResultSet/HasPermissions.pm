package Judoon::Schema::Role::ResultSet::HasPermissions;

use Moo::Role;

=pod

=encoding utf8

=head2 public

Filter down to public records

=cut

sub public {
    my ($self) = @_;
    return $self->search({permission => 'public'});
}


1;
__END__
