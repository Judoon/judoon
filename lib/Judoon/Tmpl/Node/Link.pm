package Judoon::Tmpl::Node::Link;

use Moose;
use namespace::autoclean;

with qw(
    Judoon::Tmpl::Node::Role::Base
    Judoon::Tmpl::Node::Role::Composite
    Judoon::Tmpl::Node::Role::Formatting
);

use Judoon::Tmpl::Node::VarString;
use Moose::Util::TypeConstraints qw(subtype as coerce from via);

has '+type' => (default => 'link',);

subtype 'VarStringNode',
    as 'Judoon::Tmpl::Node::VarString';
coerce 'VarStringNode',
    from 'HashRef',
    via { return Judoon::Tmpl::Node::VarString->new($_) };

has url   => (is => 'ro', isa => 'VarStringNode', required => 1, coerce => 1, );
has label => (is => 'ro', isa => 'VarStringNode', required => 1, coerce => 1, );

=head2 decompose()

This turns a C<Link> node into a list of C<Text> and C<Variable>
nodes.  This allows template producers to simplify their production
code.

=cut

sub decompose {
    my ($self) = @_;

    # open anchor tag: <a href="
    my @nodes = $self->make_text_node(q{<a href="});

    # build the nodes for the url
    push @nodes, $self->url->decompose;

    # close html link: ">
    push @nodes, $self->make_text_node(q{">});

    # add the label
    push @nodes, $self->label->decompose;

    # close a tag: </a>
    push @nodes, $self->make_text_node(q{</a>});

    return @nodes;
}


=head2 decompose_plaintext()

This turns a C<Link> node's C<label> attribute into a list of C<Text>
and C<Variable> nodes.

=cut

sub decompose_plaintext {
    my ($self) = @_;
    return $self->label->decompose_plaintext;
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
