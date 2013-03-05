package Judoon::Error::Spreadsheet::InvalidEncoding;

use Moo;
use MooX::Types::MooseLike::Base qw(Str);
extends 'Judoon::Error::Spreadsheet';

has encoding => (is => 'ro', isa => Str);


1;
__END__
