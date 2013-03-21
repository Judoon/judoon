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

Why RESTish?  Our urls follow RESTful principles, but since these
controllers are for human-interaction via HTML, we deviate in a few
ways. It does things that the REST API doesn't need to, such as adding
things to the stash where the HTML templates expect them and managing
redirects after actions are performed.  The other RESTish aspect is
that it doesn't expect that PUTs and DELETEs will be issued directly,
instead it looks for POSTs with a parameter called
'x-tunneled-method'.  If the value of 'x-tunneled-method is 'PUT', it
dispatches to the PUT action, and if it's DELETE, it dispatches to the
DELETE action.  This functionality is provided by
L<Catalyst::TraitFor::Request::REST::ForBrowsers>.

Inheriting controllers get two paths by default: C<$resource_path> and
C<$resource_path/$id>.  C<$resource_path> is the path namespace for
the controller that is set in the L</CONFIG>.  C<$id> is a valid
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
use MooseX::Types::Moose(':all');
use namespace::autoclean;

BEGIN { extends qw/
    Catalyst::Controller::DBIC::API
    Judoon::Web::Controller
/; }
use Catalyst::Controller::DBIC::API::Request::Chained;


=head1 CONFIG

=head2 C<rpc>

This is the config attribute for C<ControllerBase::Private>.  Set the
C<template_dir> and C<stash_key> keys. C<template_dir> gives the name
of the directory under C</root/src/> where the templates can be
found. C<stash_key> is key in the stash where the object, object id,
or object list should be stored.

Consuming classes should set up their path namespace by setting the
C<action> key in C<< __PACKAGE__->config() >>. Ex:

 __PACKAGE__->config(
     action => {
         base => { Chained => '/user/logged_in', PathPart => 'dataset', },
     },
     rpc => {
         template_dir => 'dataset',
         stash_key    => 'dataset',
     },
 );

=head2 inheritied config

The C<default>, C<stash_key>, and C<map> config keys are all inherited
from L<Catalyst::Controller::DBIC::API>.  Since this controller only
handles html, C<default> is 'text/html' and C<map> sets
L<Judoon::Web::View::HTML> as the default view.

=cut

has rpc => ( is  => 'ro', isa => 'HashRef', );
__PACKAGE__->config(
    rpc => {
        template_dir => undef,
        stash_key    => undef,
    },

    stash_key => 'response',
    default   => 'text/html',
    map       => {
        'text/html' => [ 'View', 'HTML', ],
    },
);


# enable our Request::Chained module on all requests
after begin => sub {
    my ($self, $c) = @_;
    Moose::Util::ensure_all_roles($c->req, 'Catalyst::Controller::DBIC::API::Request::Chained');
};


# I don't know what this is for?
around update_or_create => sub {
    my $orig = shift;
    my $self = shift;
    my $c    = shift;

    $self->$orig($c, @_);
    if ($c->stash->{created_object}) {
        %{$c->stash->{response}->{new_object}} = $c->stash->{created_object}->get_columns;
    }
};


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
    $self->objects_no_id($c);
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
to C<Catalyst::Request> so that it can call C<DBIC::API>
actions. It also de-namespaces form parameters.

=cut

sub private_base :Private {
    my ($self, $c) = @_;

    $self->deserialize($c);

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
collection of the resource.  Default template is
C<$template_dir/list.tt2>.

=cut

sub list_GET :Private {
    my ($self, $c) = @_;

    # oops. The C::C::DBIC::API list method is just called 'list',
    # exactly like the action above.  I don't want to rename my method
    # right now, so just copy-n-paste the list() code form DBIC::API
    # here.

    #$self->list($c);
    $self->list_munge_parameters($c);
    $self->list_perform_search($c);
    $self->list_format_output($c);
    # make sure there are no objects lingering
    $c->req->clear_objects();

    # end DBIC::API code

    my $key = $self->rpc->{stash_key};
    $c->stash->{$key}{list} = $c->stash->{response}{list};
    $c->stash->{template}   = $self->rpc->{template_dir} . '/list.tt2';
}


=head2 list_POST

This method is called when a POST request is made to
C</$resource_path>.  This is used to add new members to the list.
When done, redirects to the new object, i.e. C<L</object_GET>>.

=cut

sub list_POST :Private {
    my ($self, $c) = @_;
    $self->update_or_create($c);
    my $object = $c->req->get_object(0)->[0];
    $self->go_relative($c, 'object', [@{$c->req->captures}, $object->id]);
}


=head2 list_PUT

This method is called when a POST request is made to
C</$resource_path>.  This is used to update list members.  When done,
redirects back to the list (C<L</list_GET>>.

=cut

sub list_PUT :Private {
    my ($self, $c) = @_;
    $self->update_or_create($c);
    $self->go_relative($c, 'list', $c->req->captures);
}


=head2 private_id

Calls C<object_with_id>, <item>, then stores the object and id in the
stash namepace.

=cut

sub private_id :Private {
    my ($self, $c, $id) = @_;
    $self->object_with_id($c, $id);
    $self->item($c);
    my $key = $self->rpc->{stash_key};
    $c->stash->{$key}{object} = $c->stash->{response}{data};
    $c->stash->{$key}{id}     =  $c->stash->{$key}{object}{id};
}


=head2 private_chainpoint

Saves the current object into the chained object list. Also saves the
chained object into the stash namespace.

=cut

sub private_chainpoint :Private {
    my ($self, $c) = @_;

    if ($c->req->count_objects != 1) {
        $c->log->error('No object to chain from!');
        $self->push_error($c, { message => 'No object to chain from!' });
        $c->detach();
    }

    my $object = $c->req->get_object(0);
    $c->req->add_chained_object($object);
    $c->req->clear_objects();

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
a resource. Redirects back to C<object_GET> by default.

=cut

sub object_PUT :Private {
    my ($self, $c) = @_;
    $self->update_or_create($c);
    $self->go_relative($c, 'object');
}


=head2 object_DELETE

This method is called when a DELETE request is made to
C</$resource_path/$id>.  This method is used to delete an instance of
a resource. Redirects back to C<L</list_GET>> by default.

=cut

sub object_DELETE :Private {
    my ($self, $c) = @_;
    $self->delete($c);
    my @captures = @{$c->req->captures};
    pop @captures;
    $self->go_relative($c, 'list', \@captures);
}


__PACKAGE__->meta->make_immutable;

1;
__END__
