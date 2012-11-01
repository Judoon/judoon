package Judoon::Web::Model::SiteLinker;

use Moose;
use namespace::autoclean;
extends 'Catalyst::Model::Adaptor';

__PACKAGE__->config( class => 'Judoon::SiteLinker' );

__PACKAGE__->meta->make_immutable;
1;
__END__
