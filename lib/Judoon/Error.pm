package Judoon::Error;

use Moose;
use namespace::autoclean;
extends 'Throwable::Error';

has 'recoverable' => (is => 'ro', isa => 'Bool', default => 1);

__PACKAGE__->meta->make_immutable;

1;
__END__
