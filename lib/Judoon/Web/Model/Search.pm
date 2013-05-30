package Judoon::Web::Model::Search;

use Moose;
use namespace::autoclean;

extends 'Catalyst::Model::Adaptor';

__PACKAGE__->config( class => 'Judoon::Search' );

__PACKAGE__->meta->make_immutable;
1;
