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
use namespace::clean;

1;
__END__

=head1 AUTHOR

Fitz ELLIOTT <felliott@fiskur.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by the Rector and Visitors of the
University of Virginia.

This is free software, licensed under:

 The Artistic License 2.0 (GPL Compatible)

=cut
