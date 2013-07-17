package Judoon::Web::Model::TransformRegistry;

use Moose;
use namespace::autoclean;
extends 'Catalyst::Model::Adaptor';

__PACKAGE__->config( class => 'Judoon::TransformRegistry' );

__PACKAGE__->meta->make_immutable;
1;
__END__
