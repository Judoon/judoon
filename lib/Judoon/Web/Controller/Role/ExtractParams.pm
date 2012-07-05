package Judoon::Web::Controller::Role::ExtractParams;

use Moose::Role;
use namespace::autoclean;

sub extract_params {
    my ($self, $key, $params) = @_;
    my $prefix = qr{^$key\.};
    return map {my $o = $_; s/$prefix//; $_ => ($params->{$o} // '')}
        grep {m/$prefix/} keys %$params;
}

1;
__END__
