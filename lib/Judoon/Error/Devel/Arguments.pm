package Judoon::Error::Devel::Arguments;

use Moo;
extends 'Judoon::Error::Devel';

has 'expected' => (is => 'ro',);
has 'got' => (is => 'ro',);

1;
__END__
