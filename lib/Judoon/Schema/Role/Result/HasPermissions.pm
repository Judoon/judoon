package Judoon::Schema::Role::Result::HasPermissions;

use Moo::Role;

=pod

=encoding utf8

=head2 register_permissions

Register the permissions relationship with the composing class.

=cut

sub register_permissions {
    my ($class) = @_;
    $class->add_columns(
        "permission",
        { data_type => "text", is_nullable => 0, default_value => 'private', },
    );
}


=head2 is_private

Is this object a private or public?

=cut

sub is_private {
    my ($self) = @_;
    return $self->permission eq 'private';
}


1;
__END__
