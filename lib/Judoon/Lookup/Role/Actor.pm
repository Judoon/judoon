package Judoon::Lookup::Role::Actor;

use Moo::Role;

has schema        => (is => 'ro', required => 1,);
has this_table_id => (is => 'ro', required => 1,);
has that_table_id => (is => 'ro', required => 1,);

has this_joincol_id   => (is => 'ro', required => 1,);
has that_joincol_id   => (is => 'ro', required => 1,);
has that_selectcol_id => (is => 'ro', required => 1,);

requires 'result_data_type';
requires 'lookup';


1;
__END__
