package Judoon::Error::Spreadsheet::Type;

use MooX::Types::MooseLike::Base qw(ArrayRef);

use Moo;
extends 'Judoon::Error::Spreadsheet';
use namespace::clean;


has 'supported' => (
    is      => 'ro',
    isa     => ArrayRef,
    default => sub { ['xls','xlsx','csv']; }
);

1;
__END__

=pod

=for stopwords filetype

=encoding utf8

=head1 NAME

Judoon::Error::Spreadsheet::Type - Unsupported-spreadsheet format

=head1 SYNOPSIS

 if ($filetype !~ m/.*\.sxc) { #openoffice
     Judoon::Error::Spreadsheet::Type->throw({
         message  => "OpenOffice.org spreadsheets are not supported"
         filetype => 'openoffice.org 1.x',
     });
 }

=head1 ATTRIBUTES

=head2 supported

List of supported spreadsheet types.

=head2 filetype (inherited)

A string describing the type of file given.

=head1 AUTHOR

Fitz ELLIOTT <felliott@fiskur.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by the Rector and Visitors of the
University of Virginia.

This is free software, licensed under:

 The Artistic License 2.0 (GPL Compatible)

=cut
