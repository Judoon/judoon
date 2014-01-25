package Judoon::Tmpl::Node::Role::Base;

=pod

=encoding utf8

=head1 NAME

Judoon::Tmpl::Node::Role::Base - Abstract interface for Tmpl::Nodes

=head1 SYNOPSIS

 package Judoon::Tmpl::Node::NewThing;

 use Moose;
 with qw(
     Judoon::Tmpl::Node::Role::Base
 );

 <node implementation here>

=head1 DESCRIPTION

This role defines the base behavior of all Judoon::Tmpl::Nodes. It
uses C<L<MooseX::Storage>> to provide the pack() function, which lets
us convert our Nodes into simple data structures.

=cut

use Moose::Role;
use MooseX::Storage;
use namespace::autoclean;

with Storage();


=head1 ATTRIBUTES

=head2 C<type>

This attribute describes the type of the node. Since it is required
but unset, consuming classes must set a value for this by:

 has '+type' => (default => 'typename',);

=cut

has type => (is => 'ro', isa => 'Str', required => 1,);


=head1 METHODS

=head2 C<decompose>

This method returns a simpler representation of the node comprised
only of C<Text> and C<Variable> nodes.

=cut

requires 'decompose';


=head2 C<decompose_plaintext>

This method returns a the plaintext (i.e. non-HTML) components of a
node. By default, just return the result of C<decompose>.  More
elaborate Nodes an override this.

=cut

sub decompose_plaintext { shift->decompose }

1;
__END__

=head1 AUTHOR

Fitz ELLIOTT <felliott@fiskur.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by the Rector and Visitors of the
University of Virginia.

This is free software, licensed under:

 The Artistic License 2.0 (GPL Compatible)

=cut
