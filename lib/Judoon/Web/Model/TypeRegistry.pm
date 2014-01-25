package Judoon::Web::Model::TypeRegistry;

=pod

=for stopwords Adaptor

=encoding utf8

=head1 NAME

Judoon::Web::Model::TypeRegistry - Catalyst Adaptor Model for Judoon::TypeRegistry

=head1 SYNOPSIS

See L<Judoon::Web>

=head1 DESCRIPTION

L<Catalyst::Model::Adaptor> Model wrapping L<Judoon::TypeRegistry>

=cut

use Moose;
use namespace::autoclean;
extends 'Catalyst::Model::Adaptor';

__PACKAGE__->config( class => 'Judoon::TypeRegistry' );

__PACKAGE__->meta->make_immutable;
1;
__END__

=head1 AUTHOR

Fitz ELLIOTT <felliott@fiskur.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by the Rector and Visitors of the
University of Virginia.

This is free software, licensed under:

 The Artistic License 2.0 (GPL Compatible)

=cut
