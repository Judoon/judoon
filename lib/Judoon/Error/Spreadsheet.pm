package Judoon::Error::Spreadsheet;

use MooX::Types::MooseLike::Base qw(Str);

use Moo;
extends 'Judoon::Error';
use namespace::clean;


has filetype => (is => 'ro', isa => Str,);

1;
__END__

=pod

=for stopwords filetype

=encoding utf8

=head1 NAME

Judoon::Error::Spreadsheet - User provides bad spreadsheet

=head1 SYNOPSIS

 if ($filetype !~ m/.*\.gif/) {
     Judoon::Error::Spreadsheet->throw({
         message  => "Why on earth did you give me a .gif?"
         filetype => 'gif',
     });
 }

=head1 ATTRIBUTES

=head2 filetype

A string describing the type of file given.

=head1 AUTHOR

Fitz ELLIOTT <felliott@fiskur.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by the Rector and Visitors of the
University of Virginia.

This is free software, licensed under:

 The Artistic License 2.0 (GPL Compatible)

=cut
