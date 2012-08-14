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
uses C<L<MooseX::Storage>> to provide serialization.

=cut

use Moose::Role;
use MooseX::Storage;
use namespace::autoclean;

with Storage(format => 'JSON');

=head1 METHODS / ATTRIBUTES

=head2 C<pack>

=cut

around 'pack' => sub {
    my $orig = shift;
    my $self = shift;

    my $return = $self->$orig();
    $return->{type} = $self->type;
    return $return;
};


=head2 C<type>

This method simply returns a string that describes the node type.
This is a virtual method that must be implemented by subclasses.

=cut

requires 'type';


=head2 C<decompose>

This method takes a node and returns a simpler representation of it
comprised only of Text and Variable nodes.  This is a virtual method
that must be implemented by subclasses.

=cut

requires 'decompose';


1;
__END__
