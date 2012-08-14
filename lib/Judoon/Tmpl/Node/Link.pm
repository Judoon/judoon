package Judoon::Tmpl::Node::Link;

use Moose;
use namespace::autoclean;

with qw(
    Judoon::Tmpl::Node::Role::Base
    Judoon::Tmpl::Node::Role::Composite
    Judoon::Tmpl::Node::Role::Formatting
);

use Judoon::Tmpl::Factory;
use Judoon::Tmpl::Node::VarString;
use Method::Signatures;
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

method decompose {

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

__PACKAGE__->meta->make_immutable;

1;
__END__
