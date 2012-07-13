package Judoon::DB::User::Schema::ResultSet::Page;

=pod

=encoding utf8

=cut

use Moo;
use feature ':5.10';
extends 'DBIx::Class::ResultSet';
with 'Judoon::DB::User::Schema::Role::ResultSet::HasPermissions';

1;
__END__
