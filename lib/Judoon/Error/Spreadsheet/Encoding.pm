package Judoon::Error::Spreadsheet::Encoding;

use Moo;
use MooX::Types::MooseLike::Base qw(Str);
extends 'Judoon::Error::Spreadsheet';

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
