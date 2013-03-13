package Judoon::Web::Model::User;

=pod

=encoding utf8

=head1 NAME

Judoon::Web::Model::User - Catalyst DBIC Schema Model for Judoon::Schema

=head1 SYNOPSIS

See L<Judoon::Web>

=head1 DESCRIPTION

L<Catalyst::Model::DBIC::Schema> Model wrapping L<Judoon::Schema>

=cut

use Moose;
use namespace::autoclean;
extends 'Catalyst::Model::DBIC::Schema';

__PACKAGE__->config(
    schema_class => 'Judoon::Schema',
);


__PACKAGE__->meta->make_immutable;
1;
