package Judoon::DB::User::Schema::Role::Result::HasPermissions;

use Moose::Role;
use namespace::autoclean;

sub register_permissions {
    my ($class) = @_;
    $class->might_have(
        permission => 'Judoon::DB::User::Schema::Result::Permission',
        {'foreign.obj_id' => 'self.id'},
    );
}


1;
__END__
