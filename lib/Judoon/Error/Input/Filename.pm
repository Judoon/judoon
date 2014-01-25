package Judoon::Error::Input::Filename;

use Moo;
extends 'Judoon::Error::Input';
use namespace::clean;


has filename => (is => 'ro',);


1;
__END__

=pod

=encoding utf8

=head1 NAME

Judoon::Error::Input::Filename - Bad filename

=head1 SYNOPSIS

 my $file = prompt_for_file();
 if (not -e $file) {
     Judoon::Error::Input::Filename->throw({
         message  => "No such file: $file",
         filename => $file,
     });
 }

=head1 ATTRIBUTES

=head2 filename

The name of the file.

=head2 expected (inherited)

The expected value. Can be anything!

=head2 got (inherited)

The received value. Can also be anything!

=head1 AUTHOR

Fitz ELLIOTT <felliott@fiskur.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by the Rector and Visitors of the
University of Virginia.

This is free software, licensed under:

 The Artistic License 2.0 (GPL Compatible)

=cut
