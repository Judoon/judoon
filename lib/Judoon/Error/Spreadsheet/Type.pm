package Judoon::Error::Spreadsheet::Type;

use Moo;
extends 'Judoon::Error::Spreadsheet';

use MooX::Types::MooseLike::Base qw(ArrayRef);

has 'supported' => (
    is      => 'ro',
    isa     => ArrayRef,
    default => sub { ['xls','xlsx','csv']; }
);

1;
__END__
