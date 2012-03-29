package Judoon::Tmpl::Node::Newline;

use Moose;
use namespace::autoclean;

with qw(
    Judoon::Tmpl::Node::Role::Composite
    Judoon::Tmpl::Node::Role::Formatting
);

use Method::Signatures;

has value => (is => 'ro', isa => 'Str', default => "\n", );

method decompose { return $self->make_text_node("\n"); }

__PACKAGE__->meta->make_immutable;

1;
__END__
