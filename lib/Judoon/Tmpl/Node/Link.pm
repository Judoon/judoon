package Judoon::Tmpl::Node::Link;

use Moose;
use namespace::autoclean;

extends 'Judoon::Tmpl::Node';
with qw(
    Judoon::Tmpl::Node::Role::Composite
    Judoon::Tmpl::Node::Role::Formatting
);

use Judoon::Tmpl::Factory;
use List::AllUtils qw(each_arrayref);
use Method::Signatures;
use Moose::Util::TypeConstraints qw(enum);

enum 'LabelType', [qw(url static)];

sub type { return 'link'; }
has uri_text_segments     => (is => 'ro', isa => 'ArrayRef[Str]', required => 1, );
has uri_variable_segments => (is => 'ro', isa => 'ArrayRef[Str]', required => 1, );

has label_type => (is => 'ro', isa => 'LabelType', required => 1);
has label_value => (is => 'ro', isa => 'Str', );


=head2 decompose()

This turns a C<Link> node into a list of C<Text> and C<Variable>
nodes.  This allows template producers to simplify their production
code.

=cut

method decompose {

    # open anchor tag: <a href="
    my @nodes = $self->make_text_node(q{<a href="});

    # build the nodes for the url, but save them since they might be
    # needed for the label
    my @url_nodes;
    my $it = each_arrayref $self->uri_text_segments, $self->uri_variable_segments;
    while (my ($text, $var) = $it->()) {
        push @url_nodes, $self->make_text_node($text) if ($text);
        push @url_nodes, $self->make_variable_node($var) if ($var);
    }
    push @nodes, @url_nodes;

    # close html link: ">
    push @nodes, $self->make_text_node(q{">});

    # add the label
    push @nodes,
        $self->label_type eq 'url'    ? @url_nodes
      : $self->label_type eq 'static' ? $self->make_text_node($self->label_value)
      : die "Unsupported label_type: " . $self->label_type;

    # close a tag: </a>
    push @nodes, $self->make_text_node(q{</a>});


    return @nodes;
}

__PACKAGE__->meta->make_immutable;

1;
__END__
