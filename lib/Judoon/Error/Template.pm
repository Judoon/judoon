package Judoon::Error::Template;

use Moo;
use MooX::Types::MooseLike::Base qw(ArrayRef HashRef Str);
extends 'Judoon::Error';

has templates     => (is => 'ro', isa => ArrayRef[HashRef],);
has valid_columns => (is => 'ro', isa => ArrayRef[Str],);

1;
__END__
