package Judoon::Error;

use Moo;
extends 'Throwable::Error';

has 'recoverable' => (is => 'ro', default => sub {1},);

1;
__END__
