package Judoon::Error::Spreadsheet;

use Moo;
use MooX::Types::MooseLike::Base qw(Str);
extends 'Judoon::Error';

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
