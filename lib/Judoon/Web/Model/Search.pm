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

=head1 AUTHOR

Fitz ELLIOTT <felliott@fiskur.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by the Rector and Visitors of the
University of Virginia.

This is free software, licensed under:

 The Artistic License 2.0 (GPL Compatible)

=cut
