package Judoon::Lookup::Role::Group::External;

use Moo::Role;

has '+group_id'    => (is => 'ro', default => 'external');
has '+group_label' => (is => 'ro', default => 'External Database');


1;
__END__
