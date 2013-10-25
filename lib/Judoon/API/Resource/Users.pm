package Judoon::API::Resource::Users;

use Moo;
use namespace::clean;

extends 'Judoon::API::Resource';
with 'Judoon::Role::JsonEncoder';
with 'Judoon::API::Resource::Role::Set';


1;
__END__

=pod

=encoding utf8

=head1 NAME

Judoon::API::Resource::Users - A set of Users

=head1 DESCRIPTION

See L</Web::Machine::Resource>.

=cut
