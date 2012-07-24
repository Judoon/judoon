package Judoon::Web::Controller::Root;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller::ActionRole' }


use Data::Printer;

#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#
__PACKAGE__->config(namespace => '');

=pod

=encoding utf8

=head1 NAME

Judoon::Web::Controller::Root - Root Controller for Judoon::Web

=head1 DESCRIPTION

[enter your description here]

=head1 METHODS

=head2 index

The root page (/)

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    $c->stash->{template} = 'index.tt2';
}

=head2 default

Standard 404 error page

=cut

sub default :Path {
    my ( $self, $c ) = @_;
    $c->response->status(404);
    $c->serve_static_file('root/static/html/404.html');
}


=head2 base

base action. *Everything* passes through here.

=cut

sub base : Chained('') PathPart('') CaptureArgs(0) {}


=head2 denied

denied action. should probably return 501

=cut

sub denied :Chained('') PathPart('') CaptureArgs(0) {
    my ($self, $c) = @_;
    $c->stash->{template} = 'denied.tt2';
}


=head2 placeholder

action for not yet implemented actions

=cut

sub placeholder :Local {
    my ($self, $c) = @_;
    $c->flash->{message} = "Sorry, this is page is not yet implemented.";
    $c->res->redirect('/');
}


=head2 get_started

Show user the "getting started" page

=cut

sub get_started :Local {
    my ($self, $c) = @_;
    $c->stash->{template} = 'intro.tt2';
}

=head2 edit

edit action. everything that chains off this requires login.

=cut

sub edit : Chained('/login/required') PathPart('') CaptureArgs(0) {}


=head2 end

Attempt to render a view, if needed.

=cut

sub end : ActionClass('RenderView') {}



=head1 AUTHOR

Fitz Elliott

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
