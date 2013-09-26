package Judoon::Emailer;

=pod

=for stopwords VERP judoon VERPify VERP'd

=encoding utf-8

=head1 NAME

Judoon::Emailer - Send emails with automatic VERP generation

=head1 SYNOPSIS

 use Judoon::Emailer;

 my $email = Judoon::Email->new_password_reset({
     reset_uri => 'http://example.com/reset?token=deadbeef
 });

=head1 DESCRIPTION

C<Judoon::Emailer> sends email via L<Email::Sender::Simple>, first
processing it to set a VERP from on the envelope.

=cut

use Email::Address;
use Email::Sender::Simple;
use MooX::Types::MooseLike::Base qw(Str RegexpRef);

use Moo;
use namespace::clean;


=head1 ATTRIBUTES

=head2 verp_id / _build_verp_id

The prefix to our VERP from address. Default: 'judoon'

=head2 verp_domain / _build_verp_domain

The domain for our VERP from address. Default: 'cellmigration.org'

=head2 verp_regex / _build_verp_regex

A regex to recognize addressed that have already been VERP'd.

=cut

has verp_id => (
    is  => 'lazy',
    isa => Str,
);
sub _build_verp_id { return 'judoon'; }

has verp_domain => (
    is => 'lazy',
    isa => Str,
);
sub _build_verp_domain { return 'cellmigration.org'; }

has verp_regex => (
    is => 'lazy',
    isa => RegexpRef,
);
sub _build_verp_regex {
    my ($self) = @_;
    my $verp_id = $self->verp_id;
    my $verp_domain = $self->verp_domain;
    return qr{^ \Q$verp_id\E .+ \@ \Q$verp_domain\E $}x;
}


=head1 METHODS

=head2 send( $email, \%args )

This works like the L<Email::Sender::Simple> C<send> method, but first
tries to set a VERP from address on the envelope.  If a C<from>
argument is already specified in C<%args>, it respects that and does
nothing.  Otherwise, VERPify C<< $args->{to} >>, or if that doesn't
exist, the C<To:> header in C<$email>.

=cut

sub send {
    my ($self, $email, $args) = @_;

    $email = Email::Sender::Simple->prepare_email($email);

    if (not $args->{from}) {
        my $to = $args->{to} || $self->_extract_to($email);
        $args->{from} = $self->make_verp_address($to)
            unless ($self->already_verp($to));
    }

    Email::Sender::Simple->send($email, $args);
}


=head2 make_verp_address( $to_addr )

Turns an email address into a VERP address.

=cut

sub make_verp_address {
    my ($self, $to_addr) = @_;
    my $address   = Email::Address->new(undef, $to_addr);
    my $verp_addr = $self->verp_id . '+' . $address->user . '='
        . $address->host . '@' . $self->verp_domain;
    return $verp_addr;
}


=head2 already_verp( $address )

Return true if C<$address> looks like it has already been VERP'd.

=cut

sub already_verp {
    my ($self, $address) = @_;
    return $address =~ $self->verp_regex;
}


# copied--n-pasted from Email::Sender::Simple::_get_to_from
sub _extract_to {
    my ($self, $email) = @_;
    my ($to) =
      map  { $_->address               }
      grep { defined                   }
      map  { Email::Address->parse($_) }
      map  { $email->get_header($_)    }
      qw(to);
    return $to;
}


1;
__END__
