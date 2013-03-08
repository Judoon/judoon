package Judoon::Error::Devel::Foreign;

use Moo;
extends 'Judoon::Error::Devel';

use MooX::Types::MooseLike::Base qw(Str);

has 'module' => (is => 'ro', isa => Str,);
has 'foreign_message' => (is => 'ro', isa => Str,);

1;
__END__
