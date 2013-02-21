package Judoon::Web::ControllerBase::Private;

=pod

=encoding utf8

=head1 NAME

Judoon::Web::ControllerBase::Private - base class for RESTish HTML controllers

=head1 DESCRIPTION

This is the poorly-named base class for our RESTish web controllers
(C<Private::Dataset>, C<Private::DatasetColumn>, C<Private::Page>,
C<Private::PageColumn>).  It uses L<Catalyst::Action::REST> to provide
REST-like dispatch.

Why RESTish?  This controller is actually an interface to the B<real>
RESTful controllers that live in the C<API::REST::*> namespace.  This
controller is specifically for managing an HTML interface to our
database.  It does things that the REST API doesn't need to, such as
adding things to the stash where the template expect them and managing
redirects after actions are performed.  The other RESTish aspect is
that it doesn't expect that PUTs and DELETEs will be issued directly,
instead it looks for POSTs with a parameter called
'x-tunneled-method'.  If the value of 'x-tunneled-method is 'PUT', it
dispatches to the PUT action, and if it's DELETE, it dispatches to the
DELETE action.  This functionality is provided by
L<Catalyst::TraitFor::Request::REST::ForBrowsers>.

Inheriting controllers get two paths by default: C<$resource_path> and
C<$resource_path/$id>.  C<$resource_path> is the path namespace for the
controller that is set in the L</CONFIG>.  C<$id> is a valid
identifier for the resource.  Here is what happens for each HTTP verb
on each path:

  For requests to /$resource_path:
   Verb   Action       Result
   ------------------------------------------------
   GET    list_GET     list all $resource
   PUT    list_PUT     update multiple $resources
   POST   list_POST    add new $resource
   DELETE list_DELETE  <not implemented>

  For requests to /$resource_path/$id:
   Verb   Action       Result
   ------------------------------------------------
   GET    object_GET    show the $resource with id $id
   PUT    object_PUT    update the $resource
   POST   object_POST   <not implemented>
   DELETE object_DELETE delete the $resource

=cut

use Moose;
use namespace::autoclean;

BEGIN { extends 'Judoon::Web::Controller'; }

with 'Judoon::Web::Controller::Role::GoHere';

=head1 CONFIG

=head2 C<rpc>

This is the config attribute for C<ControllerBase::Private>.  Set the
C<template_dir>, C<stash_key>, and C<api_path> keys. C<template_dir>
gives the name of the directory under C</root/src/> where the
templates can be found. C<stash_key> is where in the stash the object,
id, or object list should be stored.  C<api_path> is the action path
to the corresponding C<API::REST> class.

Consuming classes should set up their path namespace by setting the
C<action> key in C<< __PACKAGE__->config() >>. Ex:

 __PACKAGE__->config(
     action => {
         base => { Chained => '/user/logged_in', PathPart => 'dataset', },
     },
     rpc => {
         template_dir => 'dataset',
         stash_key    => 'dataset',
         api_path     => 'dataset',
     },
 );

=cut

has rpc => ( is  => 'ro', isa => 'HashRef', );
__PACKAGE__->config(
    rpc => {
        template_dir => undef,
        stash_key    => undef,
        api_path     => undef,
    },
);

=head1  PATH ACTIONS

=head2 base / list / id / chainpoint / object

These are the default actions.  Only C<list> and C<object> map to
paths.  C<base> is the base for all of the other actions. C<id> is
responsible for pulling C<$id> out of the path and sticking it in the
stash.  C<list> is for actions that apply to the set of objects.
C<object> applies to one particular object. C<chainpoint> is an action
for other C<Private>-based controllers to chain from.

All of these methods (except C<list>) call private subs to do the
actual work.  This allows subclasses to override / modify the actual
functions without having to retype the Chained/PathPart/Args
attributes.

=cut

sub base : Chained('fixme') PathPart('fixme') CaptureArgs(0) {
    shift->private_base(@_);
}
sub list : Chained('base') PathPart('') Args(0) ActionClass('REST') {
    my ($self, $c) = @_;
    my $api_path = $self->rpc->{api_path};
    $c->forward("/api/rest/$api_path/objects_no_id");
}
sub id : Chained('base') PathPart('') CaptureArgs(1) {
    shift->private_id(@_);
}
sub chainpoint : Chained('id') PathPart('') CaptureArgs(0) {
    shift->private_chainpoint(@_);
}
sub object : Chained('id') PathPart('') Args(0) ActionClass('REST') {}


=head1 PRIVATE ACTIONS

=head2 private_base

The L</base> action calls this.  Code common to all actions should be
put here.  Currently applies C<Catalyst::Controller::DBIC::API> roles
to C<Catalyst::Request> so that it can forward to C<DBIC::API>
actions. It also de-namespaces form parameters.

=cut

sub private_base :Private {
    my ($self, $c) = @_;
    Catalyst::Controller::DBIC::API::Request->meta->apply($c->req)
          unless Moose::Util::does_role($c->req, 'Catalyst::Controller::DBIC::API::Request');
    Catalyst::Controller::DBIC::API::Request::Chained->meta->apply($c->req)
        unless Moose::Util::does_role($c->req, 'Catalyst::Controller::DBIC::API::Request::Chained');
    my $api_path = $self->rpc->{api_path};
    $c->forward("/api/rest/$api_path/deserialize");

    # we namespace our form params with $key.$field
    # DBIC::API wants them all to be top level.
    my $key      = $self->rpc->{stash_key};
    my $req_data = $c->req->request_data;
    if ($req_data && exists $req_data->{$key}) {
        $c->req->_set_request_data(
            ref($req_data->{$key}) eq 'ARRAY'
                ? {list => $req_data->{$key}}
                : $req_data->{$key}
         );
    }
}


=head2 list_GET

This method is called when a GET request is made to
C</$resource_path>.  Generally this method should be used to list the
collection of the resource.  Forwards to the C<list_objects> action of
the corresponding C<API::REST> controller.  Default template is
C<$template_dir/list.tt2>.

=cut

sub list_GET :Private {
    my ($self, $c) = @_;
    my $api_path = $self->rpc->{api_path};
    $c->forward("/api/rest/$api_path/list_objects");
    my $key = $self->rpc->{stash_key};
    $c->stash->{$key}{list} = $c->stash->{response}{list};
    $c->stash->{template}   = $self->rpc->{template_dir} . '/list.tt2';
}


=head2 list_POST

This method is called when a POST request is made to
C</$resource_path>.  This is used to add new members to the list.
Forwards to C<API::REST>'s C<update_or_create_objects>.  When done,
redirects to the new object, i.e. C<L</object_GET>>.

=cut

sub list_POST :Private {
    my ($self, $c) = @_;
    my $api_path = $self->rpc->{api_path};
    $c->forward("/api/rest/$api_path/update_or_create_objects");
    my $object = $c->req->get_object(0)->[0];
    $self->go_relative($c, 'object', [@{$c->req->captures}, $object->id]);
}


=head2 list_PUT

This method is called when a POST request is made to
C</$resource_path>.  This is used to update list members.
Forwards to C<API::REST>'s C<update_or_create_objects>.  When done,
redirects back to the list (C<L</list_GET>>.

=cut

sub list_PUT :Private {
    my ($self, $c) = @_;
    my $api_path = $self->rpc->{api_path};
    $c->forward("/api/rest/$api_path/update_or_create_objects");
    $self->go_relative($c, 'list', $c->req->captures);
}


=head2 private_id

Forwards to C<object_with_id>, <list_one_object>, then stores the
object and id in the stash namepace.

=cut

sub private_id :Private {
    my ($self, $c, $id) = @_;
    my $api_path = $self->rpc->{api_path};
    $c->forward("/api/rest/$api_path/object_with_id");
    $c->forward("/api/rest/$api_path/list_one_object");
    my $key = $self->rpc->{stash_key};
    $c->stash->{$key}{object} = $c->stash->{response}{data};
    $c->stash->{$key}{id}     =  $c->stash->{$key}{object}{id};
}

=head2 private_chainpoint

Forwards to C<chainpoint> in the related C<API::REST> controller. Also
saves the chained object into the stash namespace.

=cut

sub private_chainpoint :Private {
    my ($self, $c) = @_;
    my $api_path = $self->rpc->{api_path};
    $c->forward("/api/rest/$api_path/chainpoint");

    my $key = $self->rpc->{stash_key};
    $c->stash->{$key}{object} = {$c->req->get_chained_object(-1)->[0]->get_columns};
    $c->stash->{$key}{id}     = $c->stash->{$key}{object}{id};
}


=head2 object_GET

This method is called when a GET request is made to
C</$resource_path/$id>.  This method is used to view an instance
of a resource. Default template is C<$template_dir/edit.tt2>.

=cut

sub object_GET :Private {
    my ($self, $c) = @_;
    $c->stash->{template} = $self->rpc->{template_dir} . '/edit.tt2';
}


=head2 object_PUT

This method is called when a PUT request is made to
C</$resource_path/$id>.  This method is used to update an instance of
a resource. Forwards to C<update_or_create_one_object>. Redirects back
to C<object_GET> by default.

=cut

sub object_PUT :Private {
    my ($self, $c) = @_;
    my $api_path = $self->rpc->{api_path};
    $c->forward("/api/rest/$api_path/update_or_create_one_object");
    $self->go_relative($c, 'object');
}


=head2 object_DELETE

This method is called when a DELETE request is made to
C</$resource_path/$id>.  This method is used to delete an instance of
a resource. Forwards to C<delete_one_object>. Redirects back to
C<L</list_GET>> by default.

=cut

sub object_DELETE :Private {
    my ($self, $c) = @_;
    my $api_path = $self->rpc->{api_path};
    $c->forward("/api/rest/$api_path/delete_one_object");
    my @captures = @{$c->req->captures};
    pop @captures;
    $self->go_relative($c, 'list', \@captures);
}


__PACKAGE__->meta->make_immutable;

1;
__END__
