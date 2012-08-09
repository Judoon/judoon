package Judoon::Web::Controller::RPC;

=pod

=encoding utf8

=head1 NAME

Judoon::Web::Controller::RPC - base controller for RESTful controllers

=head1 DESCRIPTION

This is the poorly-named base controller for our RESTful controllers
(Dataset, DatasetColumn, Page, PageColumn).  It uses
L<Catalyst::Action::REST> to provide RESTful dispatch.

Inheriting controllers get two paths by default: C<$stash_key/> and
C<$stash_key/$id>.

  GET    $stash_key => list_GET    => list all $resource
  PUT    $stash_key => list_PUT    => manipulate list of $resource
  POST   $stash_key => list_POST   => add new $resource
  DELETE $stash_key => list_DELETE => <not implemented>

=cut

use Moose;
use namespace::autoclean;

BEGIN { extends 'Judoon::Web::Controller'; }

with 'Judoon::Web::Controller::Role::GoHere';


=head2 rpc

This is the config attribute for C<::RPC>

=cut

has rpc => ( is  => 'ro', isa => 'HashRef', );
__PACKAGE__->config(
    rpc => {
        template_dir => undef,
        stash_key    => undef,
        api_path     => undef,
    },
);


=head2 base / list / id / object

These are the default actions.  Only C<list> and C<object> map to
paths.  C<base> is the base for all of the other actions. C<id> is
responsible for pulling C<$id> out of the path and sticking it in the
stash.  C<list> is for actions that apply to the set of objects.
C<object> applies to one particular object.

All of these methods call private subs to do the actual work.  This
allows subclasses to override / modify the actual functions without
having to retype the Chained/PathPart/Args attributes.

=cut

sub base      : Chained('fixme') PathPart('fixme') CaptureArgs(0) { shift->private_base(        @_); }
sub list      : Chained('base')  PathPart('')      Args(0)        :ActionClass('REST') {
    my ($self, $c) = @_;
    my $api_path = $self->rpc->{api_path};
    $c->forward("/api/rest/$api_path/objects_no_id");
}
sub id        : Chained('base')  PathPart(''  )    CaptureArgs(1) { shift->private_id(          @_); }
sub chainpoint : Chained('id') PathPart('') CaptureArgs(0) { shift->private_chainpoint(@_); }
sub object    : Chained('id')    PathPart('')      Args(0)        :ActionClass('REST') {}


=head2 private_base

The L</base> action calls this.  Code common to all actions should be
put here.  Does nothing by default.

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
        $c->req->_set_request_data($req_data->{$key});
    }
}


=head2 list_GET

This method is called when a GET request is made to
C<$chained/$stash_key/>.  Generally this method should be used to list
the collection of the resource.  Calls C<L</get_list>> to get the
list.  Default template is C<$template_dir/list.tt2>.

=cut

sub list_GET :Private {
    my ($self, $c) = @_;
    my $api_path = $self->rpc->{api_path};
    $c->forward("/api/rest/$api_path/list_objects");
    my $key = $self->rpc->{stash_key};
    $c->stash->{$key}{list} = $c->stash->{response}{list};
    $c->stash->{template}   = $self->rpc->{template_dir} . '/list.tt2';
}


=head2 list_PUT

This method is called when a PUT request is made to
C<$chained/$stash_key/>.  I haven't decided what the exact semantics
of this is, but I'm currently use it to modify the contents of the
list, i.e. delete members.  Calls C<L</manage_list>> to manipulate the
list.  When done, redirects back to C<L</list_GET>>.

=cut


sub list_PUT :Private {
    my ($self, $c) = @_;
    my $api_path = $self->rpc->{api_path};
    $c->forward("/api/rest/$api_path/update_or_create_objects");
    $self->go_relative($c, 'list');
}


=head2 list_POST

This method is called when a POST request is made to
C<$chained/$stash_key/>.  This is used to add new members to the list.
Calls C<L</munge_add_params>> to manipulate the request parameters,
which it then returns.  These parameters are then passed to
C<L</add_object>> to add the object the list.  When done, redirects
back to the new object, i.e. C<L</object_GET>>.

=cut

sub list_POST :Private {
    my ($self, $c) = @_;
    my $api_path = $self->rpc->{api_path};
    $c->forward("/api/rest/$api_path/update_or_create_objects");
    my $object = $c->req->get_object(0)->[0];
    $self->go_relative($c, 'object', [@{$c->req->captures}, $object->id]);
}


=head2 private_id

Given the C<$id> pulled off the path by C<L</id>>, calls
C<L</validate_id>>, then C<L</get_object>>.

=cut

sub private_id :Private {
    my ($self, $c, $id) = @_;
    my $api_path = $self->rpc->{api_path};
    $c->forward("/api/rest/$api_path/object_with_id");
    $c->forward("/api/rest/$api_path/list_one_object");
    my $key = $self->rpc->{stash_key};
    $c->stash->{$key}{object} = $c->stash->{response}{data};
}

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
C<$chained/$stash_key/$id>.  This method is used to view an instance
of a resource. Default template is C<$template_dir/edit.tt2>.

=cut

sub object_GET :Private {
    my ($self, $c) = @_;
    $c->stash->{template} = $self->rpc->{template_dir} . '/edit.tt2';
}


=head2 object_PUT

This method is called when a PUT request is made to
C<$chained/$stash_key/$id>.  This method is used to update an instance
of a resource. Calls C<L</munge_edit_params>> to edit the request
params.  The edited params are then passed to
C<L</edit_object>>.  Redirects back to the object_GET by default.

=cut

sub object_PUT :Private {
    my ($self, $c) = @_;
    my $api_path = $self->rpc->{api_path};
    $c->forward("/api/rest/$api_path/update_or_create_one_object");
    $self->go_relative($c, 'object');
}


=head2 object_DELETE

This method is called when a DELETE request is made to
C<$chained/$stash_key/$id>.  This method is used to delete an instance
of a resource. Calls C<L</delete_object>>. C<L</delete_object>> is
left unimplemented by default, to force the implementor to explicitly
enable it.  Redirects back to C<L</list_GET>> by default.

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
