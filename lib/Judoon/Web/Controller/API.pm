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

=head2 base

Our base chained actions for api actions

=cut

sub base : Chained('/') PathPart('api') CaptureArgs(0) {
    my ( $self, $c ) = @_;

    if (!$c->user && (my $access_token = $c->req->param('access_token'))) {
        my $token = $c->model('User::Token')->find_by_value($access_token);

        if ($token && !$token->is_expired) {
            $c->authenticate({dbix_class => {result => $token->user}}, 'api');
        }
    }
}


=head1 AUTHOR

Fitz Elliott

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
