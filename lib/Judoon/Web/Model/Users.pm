package Judoon::Web::Model::Users;
use Moose;
extends 'Catalyst::Model::Adaptor';
__PACKAGE__->config( class => 'Judoon::DB::Users' );
__PACKAGE__->meta->make_immutable;
1;
