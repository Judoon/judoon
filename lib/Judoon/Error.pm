package Judoon::Error;

=encoding utf8

=head1 NAME

Judoon::Error - base class for our exception hierarchy

=head1 SYNOPSIS

 if ($something_went_wrong) {
     Judoon::Error->throw({message => "Oh no!"});
 }

=cut

use Moo;
extends 'Throwable::Error';

1;
__END__
