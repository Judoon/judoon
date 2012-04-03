package Judoon::Tmpl::Node::Text;

use Moose;
use namespace::autoclean;

extends 'Judoon::Tmpl::Node';
with qw(
    Judoon::Tmpl::Node::Role::Formatting
);

use Method::Signatures;

sub type { return 'text'; }
has value => (is => 'ro', isa => 'Str', required => 1,);

method decompose() { return $self; }

__PACKAGE__->meta->make_immutable;

1;
__END__
