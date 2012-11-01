package Judoon::Schema::ResultSet::Dataset;

=pod

=encoding utf8

=cut

use Moo;
use feature ':5.10';
extends 'DBIx::Class::ResultSet';
with 'Judoon::Schema::Role::ResultSet::HasPermissions';

1;
__END__
