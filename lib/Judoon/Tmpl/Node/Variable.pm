package Judoon::Tmpl::Node::Variable;

use Moose;
use namespace::autoclean;

extends 'Judoon::Tmpl::Node';
with 'Judoon::Tmpl::Node::Role::Formatting';

use Method::Signatures;

sub type { return 'variable'; }
has name => (is => 'ro', isa => 'Str', required => 1,);

__PACKAGE__->meta->make_immutable;

1;
__END__
