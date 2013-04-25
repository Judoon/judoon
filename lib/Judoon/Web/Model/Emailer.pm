package Judoon::Web::Model::Emailer;

=pod

=encoding utf8

=head1 NAME

Judoon::Web::Model::Emailer - Catalyst Adaptor Model for Judoon::Emailer

=head1 DESCRIPTION

L<Catalyst::Model::Adaptor> Model wrapping L<Judoon::Emailer>

=cut

use Moose;
use namespace::autoclean;
extends 'Catalyst::Model::Adaptor';

__PACKAGE__->config( class => 'Judoon::Emailer' );

__PACKAGE__->meta->make_immutable;
1;
__END__
