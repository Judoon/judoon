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

=head1 AUTHOR

Fitz ELLIOTT <felliott@fiskur.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by the Rector and Visitors of the
University of Virginia.

This is free software, licensed under:

 The Artistic License 2.0 (GPL Compatible)

=cut
