package Judoon::API::Resource::Page;

use Moo;
use namespace::clean;

extends 'Judoon::API::Resource';
with 'Judoon::Role::JsonEncoder';
with 'Judoon::API::Resource::Role::Item';

sub update_allows { return qw(title preamble postamble permission); }
sub update_valid  { return {permission => qr/^(?:public|private)$/}; }
with 'Judoon::API::Resource::Role::ValidateParams';


1;
__END__

=pod

=encoding utf8

=head1 NAME

Judoon::API::Resource::Page - An individual Page

=head1 DESCRIPTION

See L</Web::Machine::Resource>.

=head1 METHODS

=head2 update_allows()

List of updatable parameters.

=head2 update_valid()

List of validation checks

=cut
