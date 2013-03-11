package Judoon::Web::Model::SiteLinker;

=pod

=encoding utf8

=head1 NAME

Judoon::Web::Model::SiteLinker - Catalyst Adaptor Model for Judoon::SiteLinker

=head1 SYNOPSIS

See L<Judoon::Web>

=head1 DESCRIPTION

L<Catalyst::Model::Adaptor> Model wrapping L<Judoon::SiteLinker>

=cut

use Moose;
use namespace::autoclean;
extends 'Catalyst::Model::Adaptor';

__PACKAGE__->config( class => 'Judoon::SiteLinker' );

__PACKAGE__->meta->make_immutable;
1;
__END__
