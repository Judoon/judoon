package Judoon::Web::Controller::Role::ExtractParams;

=pod

=encoding utf8

=head1 NAME

Judoon::Web::Controller::Role::ExtractParams - get keyed parameters

=head1 SYNOPSIS

 package Judoon::Web::Controller::Dog;
 with 'Judoon::Web::Controller::Role::ExtractParams';

 sub add {
    my ($self, $c) = @_;
    my %new_dog_params = $self->extract_params('dog', $c->req->params);
    $c->model('Dog')->create(\%new_dog_params);
 }

=head1 DESCRIPTION

C<Judoon::Web::Controller::Role::ExtractParams> takes a string and a
hashref of parameters and extracts any key/val pairs where the key
begins with C<"$string\.">.  It returns a new hash with only those
key/val pairs, and scrubs C<"string\."> from the keys. e.g.

 $self->extract_params(
     'dog',
     {'dog.name' => 'fido', 'dog.age' => 3, ignored => 1}
 );
 # returns (name => 'fido', age => 3);

=cut

use Moose::Role;
use namespace::autoclean;

=head1 METHODS

=head2 extract_params($key, \%params)

see L</DESCRIPTION>.

=cut

sub extract_params {
    my ($self, $key, $params) = @_;
    my $prefix = qr{^$key\.};
    return map {my $o = $_; s/$prefix//; $_ => ($params->{$o} // '')}
        grep {m/$prefix/} keys %$params;
}

1;
__END__
