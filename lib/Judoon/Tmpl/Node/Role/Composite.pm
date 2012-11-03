package Judoon::Tmpl::Node::Role::Composite;

use Moose::Role;
use namespace::autoclean;

use Judoon::Tmpl::Node::Text;
use Judoon::Tmpl::Node::Variable;

=pod

=encoding utf8

=head2 make_text_node / make_variable_node

utility methods for building subnodes in decompose() methods

=cut

sub make_text_node {
    my ($self, $text) = @_;
    return Judoon::Tmpl::Node::Text->new({value => $text})
}

sub make_variable_node {
    my ($self, $var) = @_;
    return Judoon::Tmpl::Node::Variable->new({name => $var});
}

1;
__END__
