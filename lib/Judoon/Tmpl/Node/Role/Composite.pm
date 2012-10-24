package Judoon::Tmpl::Node::Role::Composite;

use Moose::Role;
use namespace::autoclean;

use Judoon::Tmpl::Node::Text;
use Judoon::Tmpl::Node::Variable;
use Method::Signatures;

=pod

=encoding utf8

=head2 make_text_node / make_variable_node

utility methods for building subnodes in decompose() methods

=cut

method make_text_node($text) {
    return Judoon::Tmpl::Node::Text->new({value => $text, formatting => $self->formatting,});
}

method make_variable_node($var) {
    return Judoon::Tmpl::Node::Variable->new({name => $var, formatting => $self->formatting,});
}

1;
__END__
