package Judoon::Web::Model::TransformRegistry;

use Moose;
use namespace::autoclean;
extends 'Catalyst::Model::Adaptor';

__PACKAGE__->config( class => 'Judoon::TransformRegistry' );

__PACKAGE__->meta->make_immutable;
1;
__END__

=pod

=encoding utf8

=head1 NAME

Judoon::Web::Model::TransformRegistry - Catalyst Adaptor Model for Judoon::TransformRegistry

=head1 SYNOPSIS

See L<Judoon::Web>

=head1 DESCRIPTION

L<Catalyst::Model::Adaptor> Model wrapping L<Judoon::TransformRegistry>

=cut
