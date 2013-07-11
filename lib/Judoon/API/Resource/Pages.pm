package Judoon::API::Resource::Pages;

use Moo;

extends 'Web::Machine::Resource';
with 'Judoon::Role::JsonEncoder';
with 'Judoon::API::Resource::Role::Set';

1;
__END__

=pod

=encoding utf8

=head1 NAME

Judoon::API::Resource::Pages - An set of Pages

=head1 DESCRIPTION

See L</Web::Machine::Resource>.

=cut
