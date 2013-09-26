package Judoon::API::Resource::Datasets;

use Moo;
use namespace::clean;

extends 'Web::Machine::Resource';
with 'Judoon::Role::JsonEncoder';
with 'Judoon::API::Resource::Role::Set';


1;
__END__

=pod

=encoding utf8

=head1 NAME

Judoon::API::Resource::Datasets - An set of Datasets

=head1 DESCRIPTION

See L</Web::Machine::Resource>.

=cut
