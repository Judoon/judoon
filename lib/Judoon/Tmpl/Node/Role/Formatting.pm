package Judoon::Tmpl::Node::Role::Formatting;

use Moose::Role;
use namespace::autoclean;

has formatting => (is => 'ro', isa => 'ArrayRef[Str]', default => sub { []; },);

1;
__END__
