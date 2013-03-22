package Judoon::Web::View::HTML;

=pod

=encoding utf8

=head1 NAME

Judoon::Web::View::HTML - Template Toolkit View for Judoon::Web

=head1 DESCRIPTION

Template Toolkit View for Judoon::Web.

=cut

use Moose;
use namespace::autoclean;

extends 'Catalyst::View::TT';

__PACKAGE__->config(
    TEMPLATE_EXTENSION => '.tt',
    render_die => 1,
);


=head1 SEE ALSO

L<Judoon::Web>

=head1 AUTHOR

Fitz Elliott

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable(inline_constructor => 0);
1;
