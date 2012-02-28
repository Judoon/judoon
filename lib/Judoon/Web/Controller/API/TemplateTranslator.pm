package Judoon::Web::Controller::API::TemplateTranslator;
use Moose;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller::REST'; }

use Judoon::Template::Translator;

=head1 NAME

Judoon::Web::Controller::API::TemplateTranslator - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

has template_translator => (
    is => 'ro',
    isa => 'Judoon::Template::Translator',
    lazy_build => 1,
);
sub _build_template_translator {
    return Judoon::Template::Translator->new;
}


sub base      :Chained('/api/base') PathPart('template')  CaptureArgs(0) {}
sub translate :Chained('base')     PathPart('translate') Args(0) ActionClass('REST') {}
sub translate_POST : Private {
    my ($self, $c) = @_;

    my $params = $c->req->data;
    if (not $params->{template_html}) {
        $self->status_bad_request(
            $c, message => 'No template to translate',
        );
    }

    my $template_html = $params->{template_html};
    my $template;
    try {
        $template = $self->template_translator->translate($template_html);
    }
    catch {
        my $error = $_;
        $self->status_bad_request($c, message => $error->message);
    };

    $self->status_ok($c, entity => {template => $template});
}


=head1 AUTHOR

Fitz Elliott

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
