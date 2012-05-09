package Judoon::Tmpl::Node::VarString;

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

enum 'VarStringType', [qw(static variable accession)];

sub type { return 'varstring'; }
has varstring_type    => (is => 'ro', isa => 'VarStringType', required => 1, );
has text_segments     => (is => 'ro', isa => 'ArrayRef[Str]', required => 1, );
has variable_segments => (is => 'ro', isa => 'ArrayRef[Str]', required => 1, );
has accession         => (is => 'ro', isa => 'Str');


=head2 decompose()

This turns a C<VarString> node into a list of C<Text> and C<Variable>
nodes.  This allows template producers to simplify their production
code.

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
