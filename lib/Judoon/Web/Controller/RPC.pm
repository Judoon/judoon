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


=head2 rpc

This is the config attribute for C<::RPC>

=cut

has rpc => ( is  => 'ro', isa => 'HashRef', );
__PACKAGE__->config(
    rpc => {
        template_dir => undef,
        stash_key    => undef,
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
sub list      : Chained('base')  PathPart('')      Args(0)        :ActionClass('REST') {}
sub id        : Chained('base')  PathPart(''  )    CaptureArgs(1) { shift->private_id(          @_); }
sub object    : Chained('id')    PathPart('')      Args(0)        :ActionClass('REST') {}


=head2 private_base

The L</base> action calls this.  Code common to all actions should be
put here.  Does nothing by default.

=cut

sub private_base :Private {}


=head2 list_GET

This method is called when a GET request is made to
C<$chained/$stash_key/>.  Generally this method should be used to list
the collection of the resource.  Calls C<L</get_list>> to get the
list.  Default template is C<$template_dir/list.tt2>.

=cut

sub list_GET :Private {
    my ($self, $c) = @_;
    my $key                 = $self->rpc->{stash_key};
    $c->stash->{$key}{list} = $self->get_list($c);
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
    $self->manage_list($c);
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
    my $params = $self->munge_add_params($c);
    my $object = $self->add_object($c, $params);
    $self->go_relative($c, 'object', [@{$c->req->captures}, $object->id]);
}


=head2 private_id

Given the C<$id> pulled off the path by C<L</id>>, calls
C<L</validate_id>>, then C<L</get_object>>.

=cut

sub private_id :Private {
    my ($self, $c, $id) = @_;
    my $key                   = $self->rpc->{stash_key};
    $c->stash->{$key}{id}     = $self->validate_id($c, $id);
    $c->stash->{$key}{object} = $self->get_object($c);
}


=head2 object_GET

This method is called when a GET request is made to
C<$chained/$stash_key/$id>.  This method is used to view an instance
of a resource. Default template is C<$template_dir/edit.tt2>.

=cut

sub object_GET :Private {
    my ($self, $c) = @_;
    $c->stash->{template}   = $self->rpc->{template_dir} . '/edit.tt2';
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
    my $params                = $self->munge_edit_params($c);
    my $key                   = $self->rpc->{stash_key};
    $c->stash->{$key}{object} = $self->edit_object($c, $params);
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
    $self->delete_object($c);
    my @captures = @{$c->req->captures};
    pop @captures;
    $self->go_relative($c, 'list', \@captures);
}


=head2 hook subs

Theses are the subs an inheriting subclass should implement

=head3 get_list($c)

Takes a context object, returns an arrayref of object resources.

=head3 manage_list($c)

Takes a context object, updates the list of object resources. Returns
nothing. Default sub is a no-op;

=head3 munge_add_params($c)

Takes a context object, returns a hashref of params, suitable for
passing to C<create()>.

=head3 add_object($c, $params)

Takes a context object and hashref of params. Should create object and
return it.  Does nothing by default.

=head3 validate_id($c, $id)

Takes a context object and the id.  Should return a validated id or
die. Passes through C<$id> by default.

=head3 get_object($c)

Takes a context object and returns the object with the id in
C<< $stash->{$stash_key}{id} >>.  Is a no-op by default.

=head3 munge_edit_params($c)

Takes context object, return a hashref of parameters suitable for
feeding to C<< $dbic_row->update() >>.

=head3 edit_object($c, $params)

Takes context object and params from C<L</munge_edit_params>>, updates
the row object in C<< $c->stash->{$stash_key}{object} >>. Returns the
object.

=head3 delete_object($c)

Takes a context object, deletes the object in C<<
$c->stash->{$stash_key}{object} >>, returns nothing. Unimplemented by
default.

=cut

sub get_list          :Private { return [];    }
sub manage_list       :Private { return; }
sub munge_add_params  :Private { return $_[1]->req->params; }
sub add_object        :Private { return undef; }
sub validate_id       :Private { return $_[2]; }
sub get_object        :Private { return undef; }
sub munge_edit_params :Private { return $_[1]->req->params; }
sub edit_object       :Private { return undef; }
sub delete_object     :Private { return;       }


__PACKAGE__->meta->make_immutable;

1;
__END__
