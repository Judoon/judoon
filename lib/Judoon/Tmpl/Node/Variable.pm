package Judoon::Tmpl::Node::Variable;

use Moose;
use namespace::autoclean;

with qw(
    Judoon::Tmpl::Node::Role::Base
    Judoon::Tmpl::Node::Role::Formatting
);


our $AUTHORITY = '';

has '+type' => (default => 'variable',);
has name => (is => 'ro', isa => 'Str', required => 1,);

sub decompose { return shift; }

__PACKAGE__->meta->make_immutable;

1;
__END__
