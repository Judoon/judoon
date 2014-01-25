package Judoon::Tmpl::Node::VarString;

=pod

=encoding utf-8

=for stopwords linkbuilder

=head1 NAME

Judoon::Tmpl::Node::VarString - Represents mixed static/variable text

=head1 DESCRIPTION

A L<Judoon::Tmpl::Node::VarString> is not a node that is inserted
directly by the user.  Rather it is a sub-component of other Node
types.  It represents a string with both static and variable parts.
The static parts are stored in the C<text_segments> attribute, while
the variable parts are stored in the C<variable_segments> attribute.

When the C<VarString> is being decomposed, it is always assumed that
the first base node will come from the C<text_segments> attribute. So,
for example, given a C<VarString> with the following contents:

 $self->text_segments(['foo','baz']);
 $self->variable_segments(['bar','quux']);

...the following javascript template string would be produced:

 foo{{bar}}baz{{quux}}

If the expression represented by a C<VarString> begins with a
variable, then the first element of C<text_segments> should be the
empty string.

=cut

use Moose;
use namespace::autoclean;

with qw(
    Judoon::Tmpl::Node::Role::Base
    Judoon::Tmpl::Node::Role::Composite
    Judoon::Tmpl::Node::Role::Formatting
);

use List::AllUtils qw(each_arrayref);
use Moose::Util::TypeConstraints qw(enum);

enum 'VarStringType', [qw(static variable accession)];

=head1 ATTRIBUTES

=head2 type

The type is C<varstring>.

=head2 varstring_type

One of C<static>, C<variable>, or C<accession>.  This is
meta-information that we need to easily populate the linkbuilder form
widget on the website.  If C<accession>, the name of the site being
linked to is stored in the C<accession> attribute.

=head2 accession

The name of the site being linked to.

=head2 text_segments

A list of strings that will be decomposed into plain C<Text> nodes.

=head2 variable_segments

A list of variable names that will be decomposed into C<Variable>
nodes.

=cut

has '+type' => (default => 'varstring',);
has varstring_type    => (is => 'ro', isa => 'VarStringType', required => 1, );
has text_segments     => (is => 'ro', isa => 'ArrayRef[Str]', required => 1, );
has variable_segments => (is => 'ro', isa => 'ArrayRef[Str]', required => 1, );
has accession         => (is => 'ro', isa => 'Str', default => '',);


=head1 METHODS

=head2 decompose()

This turns a C<VarString> node into a list of C<Text> and C<Variable>
nodes.  This allows template producers to simplify their production
code.  The nodes are zipped, with the C<Text> nodes always being
created first.  This means that if you want your string to start with
a C<Variable>, you need to prepend an empty string to
C<text_segments>.

=cut

sub decompose {
    my ($self) = @_;

    my @nodes;
    my $it = each_arrayref $self->text_segments, $self->variable_segments;
    while (my ($text, $var) = $it->()) {
        push @nodes, $self->make_text_node($text) if ($text);
        push @nodes, $self->make_variable_node($var) if ($var);
    }

    return @nodes;
}



__PACKAGE__->meta->make_immutable;

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
