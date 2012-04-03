package Judoon::Tmpl::Node::Role::Composite;

use Moose::Role;
use namespace::autoclean;

use Judoon::Tmpl::Factory;
use Method::Signatures;


method make_text_node($text) {
    return Judoon::Tmpl::Factory::new_text_node({value => $text, formatting => $self->formatting,});
}

method make_variable_node($var) {
    return Judoon::Tmpl::Factory::new_variable_node({name => $var, formatting => $self->formatting,});
}

1;
__END__
