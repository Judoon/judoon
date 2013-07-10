package Judoon::Web::Model::Search;

use Moose;
use namespace::autoclean;

extends 'Catalyst::Model::Adaptor';

__PACKAGE__->config( class => 'Judoon::Search' );

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding utf8

=head1 NAME

Judoon::Web::Model::Search - Model Adaptor for L<Judoon::Search>

=head1 DESCRIPTION

This module L</Catalyst::Model> that is just a thin wrapper around
L<Judoon::Search>, our interface to our ElasticSearch search engine.

=cut
