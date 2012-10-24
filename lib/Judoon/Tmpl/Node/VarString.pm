package Judoon::Tmpl::Node::VarString;

use Moose;
use namespace::autoclean;

with qw(
    Judoon::Tmpl::Node::Role::Base
    Judoon::Tmpl::Node::Role::Composite
    Judoon::Tmpl::Node::Role::Formatting
);

use List::AllUtils qw(each_arrayref);
use Method::Signatures;
use Moose::Util::TypeConstraints qw(enum);

enum 'VarStringType', [qw(static variable accession)];

has '+type' => (default => 'varstring',);
has varstring_type    => (is => 'ro', isa => 'VarStringType', required => 1, );
has text_segments     => (is => 'ro', isa => 'ArrayRef[Str]', required => 1, );
has variable_segments => (is => 'ro', isa => 'ArrayRef[Str]', required => 1, );
has accession         => (is => 'ro', isa => 'Str', default => '',);


=head2 decompose()

This turns a C<VarString> node into a list of C<Text> and C<Variable>
nodes.  This allows template producers to simplify their production
code.  The nodes are zipped, with the C<Text> nodes always being
created first.  This means that if you want your string to start with
a C<Variable>, you need to prepend an empty string to
C<text_segments>.

=cut

method decompose {

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
