package Judoon::Transform::Role::Base;

use Moo::Role;


requires 'result_data_type';
requires 'result_accession_type';
requires 'apply_batch';


1;
__END__
