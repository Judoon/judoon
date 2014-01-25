package Judoon::Web::Controller::Root;

=pod

=encoding utf8

=head1 NAME

Judoon::Web::Controller::Root - Root Controller for Judoon::Web

=head1 DESCRIPTION

This is the Root controller for L<Judoon::Web>.  Default actions, and
basic actions that don't fit anywhere else go here.

=cut


use Moose;
use namespace::autoclean;

BEGIN { extends 'Judoon::Web::Controller' }


#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#
__PACKAGE__->config(namespace => '');


=head1 METHODS

=head2 index

The root page (/)

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;
    $c->stash->{template} = 'index.tt2';
}


=head2 error

Standard 500 error page

=cut

sub error : Path('error') {
    my ( $self, $c ) = @_;
    $c->response->status(500);
    $c->serve_static_file('root/static/html/500.html');
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
    if ($c->user_exists) {
        $self->set_error($c, q{You don't have permission to see that page});
        $self->go_here($c, '/jsapp/user_view', [$c->user->username]);
    }
    else {
        $c->stash->{template} = 'denied.tt2';
    }
}


=head2 placeholder

action for not yet implemented actions

=cut

sub placeholder :Local {
    my ($self, $c) = @_;
    $self->set_warning($c, "Sorry, this is page is not yet implemented.");
    $c->res->redirect('/');
}


=head2 end

Attempt to render a view, if needed.

=cut

sub end : ActionClass('RenderView') {}


__PACKAGE__->meta->make_immutable;

1;

=head1 AUTHOR

Fitz ELLIOTT <felliott@fiskur.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by the Rector and Visitors of the
University of Virginia.

This is free software, licensed under:

 The Artistic License 2.0 (GPL Compatible)

=cut
