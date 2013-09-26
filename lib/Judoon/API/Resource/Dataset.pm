package Judoon::API::Resource::Dataset;

use Moo;
use namespace::clean;

extends 'Web::Machine::Resource';
with 'Judoon::Role::JsonEncoder';
with 'Judoon::API::Resource::Role::Item';


1;
__END__

=pod

=encoding utf8

=head1 NAME

Judoon::API::Resource::Dataset - An individual Dataset

=head1 DESCRIPTION

See L</Web::Machine::Resource>.

=cut
