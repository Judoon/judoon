package Judoon::Error::Fatal;

use Moo;
extends 'Judoon::Error';

has '+recoverable' => (default => sub { 0 },);

1;
__END__
