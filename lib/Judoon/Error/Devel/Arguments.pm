package Judoon::Error::Devel::Arguments;

use Moo;
extends 'Judoon::Error::Devel';
use namespace::clean;

has 'expected' => (is => 'ro',);
has 'got' => (is => 'ro',);


1;
__END__

=pod

=encoding utf8

=head1 NAME

Judoon::Error::Devel::Arguments - Unexpected arguments!

=head1 SYNOPSIS

 my %noises = {moo => \@data};
 do_with_moo( $noises{mom} ); #undef

 sub do_with_moo {
   my ($moo_args) = @_;

   if (ref $moo_args ne 'ARRAY') {
     Judoon::Error::Devel::Arguments->throw({
       message  => "arg to do_with_moo() must be arrayref!",
       got      => ref($moo_args),
       expected => 'arrayref',
     });
   }

=head1 DESCRIPTION

This error type is for when a function or subroutine is called
incorrectly.  It's functionally identical to C<Judoon::Error::Input>,
but is intended for code that doesn't handle user input directly.
Throwing this indicates programmer error, not user error.

=head1 ATTRIBUTES

=head2 expected

The expected value. Can be anything!

=head2 got

The received value. Can also be anything!
