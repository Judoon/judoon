package Judoon::Tmpl::Node::Role::Composite;

use Moose::Role;
use namespace::autoclean;

use Judoon::Tmpl::Factory;
use Method::Signatures;


requires 'decompose';

has factory => (
    is  => 'ro',
    isa => 'Judoon::Tmpl::Factory',
    lazy_build => 1,
);
sub _build_factory { return Judoon::Tmpl::Factory->new; }


method make_text_node($text) {
    return $self->factory->build({
        type => 'text', value => $text,
        formatting => $self->formatting,
    });
}

method make_variable_node($var) {
    return $self->factory->build({
        type => 'variable', value => $var,
        formatting => $self->formatting,
    });
}

1;
__END__
