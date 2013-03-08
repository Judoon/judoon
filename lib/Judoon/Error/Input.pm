package Judoon::Error::Input;

use Moo;
extends 'Judoon::Error';

has 'expected' => (is => 'ro',);
has 'got'      => (is => 'ro',);


1;
__END__
