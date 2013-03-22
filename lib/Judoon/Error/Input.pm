package Judoon::Error::Input;

=encoding utf8

=head1 NAME

Judoon::Error::Input - User provides bad input exception

=head1 SYNOPSIS

 my $number = prompt_for_number();
 if ($number !~ m/^\d+$/) {
     Judoon::Error->throw({
         message  => "That's not a number",
         got      => $number,
         expected => 'a number: qr{^\d+$}'
     });
 }

=cut

use Moo;
extends 'Judoon::Error';


=head1 ATTRIBUTES

=head2 expected

The expected value. Can be anything!

=head2 got

The received value. Can also be anything!

=cut

has 'expected' => (is => 'ro',);
has 'got'      => (is => 'ro',);


1;
__END__
