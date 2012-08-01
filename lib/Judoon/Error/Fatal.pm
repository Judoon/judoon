package Judoon::Error::Fatal;

use Moose;
use namespace::autoclean;

extends 'Judoon::Error';

has '+recoverable' => (default => 0);

__PACKAGE__->meta->make_immutable(inline_constructor => 0);
1;
__END__
