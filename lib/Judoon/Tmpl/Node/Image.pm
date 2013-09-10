package Judoon::Tmpl::Node::Image;

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

subtype 'VarStringNode2',
    as 'Judoon::Tmpl::Node::VarString';
coerce 'VarStringNode2',
    from 'HashRef',
    via { return Judoon::Tmpl::Node::VarString->new($_) };

has url   => (is => 'ro', isa => 'VarStringNode2', required => 1, coerce => 1, );


=head2 decompose()

This turns an C<Image> node into a list of C<Text> and C<Variable>
nodes.  This allows template producers to simplify their production
code.

=cut

sub decompose {
    my ($self) = @_;

    # open anchor tag: <img src="
    my @nodes = $self->make_text_node(q{<img src="});

    # build the nodes for the url
    push @nodes, $self->url->decompose;

    # close html link: ">
    push @nodes, $self->make_text_node(q{">});

    return @nodes;
}

__PACKAGE__->meta->make_immutable;

1;
__END__
