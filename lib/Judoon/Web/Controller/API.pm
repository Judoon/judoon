package Judoon::Web::Controller::API;
use Moose;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

Judoon::Web::Controller::API - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 base / index

Basically Nothing

=cut

sub base  :Chained('/base') PathPart('api') CaptureArgs(0) {}
sub index :Chained('base')  PathPart('')    Args(0) {
    my ($self, $c) = @_;
    $c->res->body('got here');
}

=head1 AUTHOR

Fitz Elliott

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
