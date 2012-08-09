package Judoon::Web::Controller::API::REST;

use Moose;
use namespace::autoclean;

BEGIN { extends qw/Catalyst::Controller/; }

sub rest_base : Chained('/api/api_base') PathPart('') CaptureArgs(0) {
    my ($self, $c) = @_;
}

__PACKAGE__->meta->make_immutable;
1;
