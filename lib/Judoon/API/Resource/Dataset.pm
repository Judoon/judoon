package Judoon::API::Resource::Dataset;

use Moo;
use namespace::clean;

extends 'Judoon::API::Resource';
with 'Judoon::Role::JsonEncoder';
with 'Judoon::API::Resource::Role::Item';
with 'Judoon::API::Resource::Role::Tabular';

sub update_allows { return qw(name description permission); }
sub update_valid  { return {permission => qr/^(?:public|private)$/}; }
with 'Judoon::API::Resource::Role::ValidateParams';


1;
__END__

=pod

=encoding utf8

=head1 NAME

Judoon::API::Resource::Dataset - An individual Dataset

=head1 DESCRIPTION

See L</Web::Machine::Resource>.

=head1 METHODS

=head2 update_allows()

List of updatable parameters.

=head2 update_valid()

List of validation checks

=head1 AUTHOR

Fitz ELLIOTT <felliott@fiskur.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by the Rector and Visitors of the
University of Virginia.

This is free software, licensed under:

 The Artistic License 2.0 (GPL Compatible)

=cut
