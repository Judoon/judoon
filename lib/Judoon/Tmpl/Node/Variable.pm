package Judoon::Tmpl::Node::Variable;

=pod

=encoding utf8

=head1 NAME

Judoon::Tmpl::Node::Variable - A Node that represents variable data

=cut

use Moose;
use namespace::autoclean;

with qw(
    Judoon::Tmpl::Node::Role::Base
    Judoon::Tmpl::Node::Role::Formatting
);


# workaround for a bug in Package::Stash::XS
# see https://rt.cpan.org/Public/Bug/Display.html?id=80497
our $AUTHORITY = '';


=head1 ATTRIBUTES

=head2 name

The name of the variable.  Must correspond to a C<shortname> in the
L<Judoon::Schema::Result::DatasetColumn> table.

=cut

has '+type' => (default => 'variable',);
has name => (is => 'ro', isa => 'Str', required => 1,);


=head1 METHODS

=head2 decompose

A C<Variable> node is one of the base node types and so decomposes to
itself.

=cut

sub decompose { return shift; }



__PACKAGE__->meta->make_immutable;

1;
__END__
