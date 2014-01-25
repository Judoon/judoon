package Judoon::Error::Spreadsheet::Encoding;

use MooX::Types::MooseLike::Base qw(Str);

use Moo;
extends 'Judoon::Error::Spreadsheet';
use namespace::clean;

has encoding => (is => 'ro', isa => Str);


1;
__END__

=pod

=encoding utf8

=head1 NAME

Judoon::Error::Spreadsheet::Encoding - User provides bad spreadsheet

=head1 SYNOPSIS

 if ($encoding !~ m/latin1|utf8|ascii/) {
     Judoon::Error::Spreadsheet::Encoding->throw({
         message  => "Unsupported spreadsheet encoding: $encoding",
         encoding => $encoding,
     });
 }

=head1 ATTRIBUTES

=head2 encoding

Encoding type of given spreadsheet.

=head1 AUTHOR

Fitz ELLIOTT <felliott@fiskur.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by the Rector and Visitors of the
University of Virginia.

This is free software, licensed under:

 The Artistic License 2.0 (GPL Compatible)

=cut
