package Judoon::DB::User::Schema::Role::Result::HasPermissions;

use Moose::Role;
use namespace::autoclean;


=pod

=encoding utf8

=head2 register_permissions

Register the permissions relationship with the composing class.

=cut

sub register_permissions {
    my ($class) = @_;
    $class->might_have(
        permission => 'Judoon::DB::User::Schema::Result::Permission',
        {'foreign.obj_id' => 'self.id'},
    );
}


1;
__END__
