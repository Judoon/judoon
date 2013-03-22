package Judoon::Web::Controller::API;

=pod

=encoding utf8

=head1 NAME

Judoon::Web::Controller::API - Root Controller for API actions

=cut

use Moose;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller'; }


=head1 ACTIONS

=head2 base / index

Does nothing currently.

=cut

sub base  :Chained('/base') PathPart('api') CaptureArgs(0) {}
sub index :Chained('base')  PathPart('')    Args(0) {
    my ($self, $c) = @_;
    $c->res->body('got here');
}

=head2 api_base

Our base chained actions for api actions

=cut

sub api_base : Chained('/') PathPart('api') CaptureArgs(0) {
    my ( $self, $c ) = @_;
}


=head1 AUTHOR

Fitz Elliott

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
