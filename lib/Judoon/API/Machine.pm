package Judoon::API::Machine;

use Moo;
extends 'Web::Machine';
use namespace::clean;

use Web::Machine::I18N::en;
$Web::Machine::I18N::en::Lexicon{422} = 'Unprocessable Entity';

1;
__END__

=pod

=encoding utf8

=head1 NAME

Judoon::API::Machine - Web::Machine-based REST interface to Judoon

=head1 DESCRIPTION

See L</Web::Machine>.

=head1 AUTHOR

Fitz ELLIOTT <felliott@fiskur.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by the Rector and Visitors of the
University of Virginia.

This is free software, licensed under:

 The Artistic License 2.0 (GPL Compatible)

=cut
