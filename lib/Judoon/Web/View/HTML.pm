package Judoon::Web::View::HTML;

=pod

=encoding utf8

=head1 NAME

Judoon::Web::View::HTML - Template Toolkit View for Judoon::Web

=head1 DESCRIPTION

Template Toolkit View for Judoon::Web.

=cut

BEGIN {use HTML::String::TT;}

use Moose;
use namespace::autoclean;

extends 'Catalyst::View::TT';

use HTML::Restrict;


__PACKAGE__->config(
    CLASS              => 'HTML::String::TT',
    TEMPLATE_EXTENSION => '.tt',
    render_die         => 1,
    expose_methods     => [qw(strip_html uri_for_action)],
);


=head1 METHODS

=head2 uri_for_action

Provide the C<uri_for_action> context object method to the template.

=cut

sub uri_for_action {
    my $self   = shift;
    my $c      = shift;
    my $action = shift;
    return $c->uri_for_action("$action", @_);
}


=head2 strip_html

Remove all HTML from the input string.

=cut

sub strip_html {
    my ($self, $c, $input) = @_;
    return HTML::Restrict->new->process($input);
}


__PACKAGE__->meta->make_immutable(inline_constructor => 0);
1;

=head1 AUTHOR

Fitz ELLIOTT <felliott@fiskur.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by the Rector and Visitors of the
University of Virginia.

This is free software, licensed under:

 The Artistic License 2.0 (GPL Compatible)

=cut
