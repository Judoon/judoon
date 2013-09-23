package Judoon::Lookup::Role::Group::Internal;

use Moo::Role;

has '+group_id'    => (is => 'ro', default => 'internal');
has '+group_label' => (is => 'ro', default => 'My Datasets');


1;
__END__
