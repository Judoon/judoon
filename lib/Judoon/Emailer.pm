package Judoon::Emailer;

use Moo;
use MooX::Types::MooseLike::Base qw(Str RegexpRef);

use Email::Address;
use Email::Sender::Simple;


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


sub make_verp_address {
    my ($self, $to_addr) = @_;
    my $address   = Email::Address->new(undef, $to_addr);
    my $verp_addr = $self->verp_id . '+' . $address->user . '='
        . $address->host . '@' . $self->verp_domain;
    return $verp_addr;
}


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
