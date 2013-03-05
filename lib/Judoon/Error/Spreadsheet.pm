package Judoon::Error::Spreadsheet;

use Moo;
use MooX::Types::MooseLike::Base qw(ArrayRef HashRef Str);
extends 'Judoon::Error';

has filetype => (is => 'ro', isa => Str,);

1;
__END__
