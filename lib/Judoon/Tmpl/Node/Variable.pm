package Judoon::Tmpl::Node::Variable;

use Moose;
use namespace::autoclean;

with 'Judoon::Tmpl::Node::Role::Formatting';

use Method::Signatures;

has name => (is => 'ro', isa => 'Str', required => 1,);

__PACKAGE__->meta->make_immutable;

1;
__END__
