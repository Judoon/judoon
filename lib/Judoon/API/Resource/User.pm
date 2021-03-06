package Judoon::API::Resource::User;

use Moo;
use namespace::clean;

extends 'Judoon::API::Resource';
with 'Judoon::Role::JsonEncoder';
with 'Judoon::API::Resource::Role::Item';

sub update_allows { return qw(name); }
sub update_valid  { return {}; }
with 'Judoon::API::Resource::Role::ValidateParams';


sub allowed_methods {
    my ($self) = @_;
     return [
        qw(GET HEAD),
        ( $_[0]->writable ) ? (qw(PUT)) : ()
    ];
}


1;
__END__

=pod

=encoding utf8

=head1 NAME

Judoon::API::Resource::User - An individual User

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
