package Judoon::DB::User::Schema::Role::ResultSet::HasPermissions;

use Moo::Role;

=pod

=encoding utf8

=head2 public

Filter down to public records

=cut

sub public {
    my ($self) = @_;
    return $self->search({permission => 'public'}, {join => 'permission'});
}


1;
__END__
