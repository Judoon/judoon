package Judoon::Web::ControllerBase::Private;

=pod

=for stopwords de-namespaces

=encoding utf8

=head1 NAME

Judoon::Web::ControllerBase::Private - base class for CRUD-y HTML controllers

=head1 DESCRIPTION

This is the poorly-named base class for our CRUD web controllers
(C<Private::Dataset>, C<Private::DatasetColumn>, C<Private::Page>,
C<Private::PageColumn>).  It uses L<Catalyst::Action::REST> to provide
REST-like dispatch.

Why REST-like?  Our urls follow RESTful principles, but since these
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
    Judoon::Web::Controller
/; }


with 'Catalyst::Controller::DBIC::API::StoredResultSource',
     'Catalyst::Controller::DBIC::API::StaticArguments';
with 'Catalyst::Controller::DBIC::API::RequestArguments' => { static => 1 };

use Catalyst::Controller::DBIC::API::Request;
use Catalyst::Controller::DBIC::API::Request::Chained;
use CGI::Expand ();
use DBIx::Class::ResultClass::HashRefInflator;
use JSON ();
use Moose::Util;
use Scalar::Util('blessed', 'reftype');
use Test::Deep::NoTest('eq_deeply');
use Try::Tiny;


has '_json' => (
    is => 'ro',
    isa => 'JSON',
    lazy_build => 1,
);

sub _build__json {
    # no ->utf8 here because the request params get decoded by Catalyst
    return JSON->new;
}


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

=head2 inherited config

The C<default>, C<stash_key>, and C<map> config keys are all inherited
from L<Catalyst::Controller::DBIC::API>.  Since this controller only
handles html, C<default> is 'text/html' and C<map> sets
L<Judoon::Web::View::HTML> as the default view.

=cut

has rpc => ( is  => 'ro', isa => HashRef, );
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


=for Pod::Coverage begin

=cut

# enable our DBIC::API::Request* roles on all requests
sub begin :Private {
    my ($self, $c) = @_;
    Moose::Util::ensure_all_roles($c->req, 'Catalyst::Controller::DBIC::API::Request');
    Moose::Util::ensure_all_roles($c->req, 'Catalyst::Controller::DBIC::API::Request::Chained');
}


=head1  PATH ACTIONS

=head2 base / list / id / chainpoint / object

These are the default actions.  Only C<list> and C<object> map to
paths.  C<base> is the base for all of the other actions. C<id> is
responsible for pulling C<$id> out of the path and sticking it in the
stash.  C<list> is for actions that apply to the set of objects.
C<object> applies to one particular object. C<chainpoint> is an action
for other C<Private>-based controllers to chain from.

All of these methods call private subs to do the actual work.  This
allows subclasses to override / modify the actual functions without
having to retype the Chained/PathPart/Args attributes.

=cut

sub base : Chained('fixme') PathPart('fixme') CaptureArgs(0) {
    shift->private_base(@_);
}
sub list : Chained('base') PathPart('') Args(0) ActionClass('REST') {
    shift->private_list(@_);
}
sub id : Chained('base') PathPart('') CaptureArgs(1) {
    shift->private_id(@_);
}
sub chainpoint : Chained('id') PathPart('') CaptureArgs(0) {
    shift->private_chainpoint(@_);
}
sub object : Chained('id') PathPart('') Args(0) ActionClass('REST') {
    shift->private_object(@_);
}


=head1 PRIVATE ACTIONS

=head2 private_base

The L</base> action calls this.  Code common to all actions should be
put here.  Currently applies C<Catalyst::Controller::DBIC::API> roles
to C<Catalyst::Request> so that it can call C<DBIC::API>
actions. It also de-namespaces form parameters.

=cut

sub private_base :Private {
    my ($self, $c) = @_;

    my $req_params;

    if ($c->req->data && scalar(keys %{$c->req->data})) {
        $req_params = $c->req->data;
    }
    else {
        $req_params = CGI::Expand->expand_hash($c->req->params);

        my @param_list = @{[
            $self->search_arg, $self->count_arg, $self->page_arg,
            $self->offset_arg, $self->ordered_by_arg, $self->grouped_by_arg,
            $self->prefetch_arg,
        ]};
        foreach my $param (@param_list) {
            # these params can also be composed of JSON
            # but skip if the parameter is not provided
            next if not exists $req_params->{$param};

            # find out if CGI::Expand was involved
            if (ref $req_params->{$param} eq 'HASH') {
                for my $key ( keys %{$req_params->{$param}} ) {
                    # copy the value because JSON::XS will alter it
                    # even if decoding failed
                    my $value = $req_params->{$param}->{$key};
                    try {
                        my $deserialized = $self->_json->decode($value);
                        $req_params->{$param}->{$key} = $deserialized;
                    }
                    catch {
                        $c->log->debug("Param '$param.$key' did not deserialize appropriately: $_")
                            if $c->debug;
                    };
                }
            }
            else {
                try {
                    my $value = $req_params->{$param};
                    my $deserialized = $self->_json->decode($value);
                    $req_params->{$param} = $deserialized;
                }
                catch {
                    $c->log->debug("Param '$param' did not deserialize appropriately: $_")
                        if $c->debug;
                };
            }
        }
    }

    $self->inflate_request($c, $req_params);

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


=head2 private_list

Incorporates L</Catalyst::Controller::DBIC::API>'s C<objects_no_id>
action.

=cut

sub private_list {
    my ($self, $c) = @_;

    if ($c->req->has_request_data) {
        my $data = $c->req->request_data;
        my $vals;

        if (exists($data->{$self->data_root}) && defined($data->{$self->data_root})) {
            my $root = $data->{$self->data_root};
            if (reftype($root) eq 'ARRAY') {
                $vals = $root;
            }
            elsif (reftype($root) eq 'HASH') {
                $vals = [$root];
            }
            else {
                $c->log->error('Invalid request data');
                $c->error('Invalid request data');
                $c->detach();
            }
        }
        else {
            # no data root, assume the request_data itself is the payload
            $vals = [$c->req->request_data];
        }

        foreach my $val (@$vals) {
            unless (exists($val->{id})) {
                $c->req->add_object([$c->req->current_result_set->new_result({}), $val]);
                next;
            }

            try {
                $c->req->add_object([$self->object_lookup($c, $val->{id}), $val]);
            }
            catch {
                $c->detach('/default');
            };
        }
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
stash namespace.

=cut

sub private_id :Private {
    my ($self, $c, $id) = @_;

    my $vals = $c->req->request_data->{$self->data_root};
    unless(defined($vals)) {
        # no data root, assume the request_data itself is the payload
        $vals = $c->req->request_data;
    }


    try {
        # there can be only one set of data
        $c->req->add_object([$self->object_lookup($c, $id), $vals]);
    }
    catch {
        $c->detach('/default');
    };


    $self->item($c);

    my $key = $self->rpc->{stash_key};
    $c->stash->{$key}{object} = $c->stash->{response}{data};
    $c->stash->{$key}{id}     = $c->stash->{$key}{object}{id};
}


=head2 private_chainpoint

Saves the current object into the chained object list. Also saves the
chained object into the stash namespace.

=cut

sub private_chainpoint :Private {
    my ($self, $c) = @_;

    if ($c->req->count_objects != 1) {
        $c->log->error('No object to chain from!');
        $c->error('No object to chain from!');
        $c->detach();
    }

    my $object = $c->req->get_object(0);
    $c->req->add_chained_object($object);
    $c->req->clear_objects();

    my $key = $self->rpc->{stash_key};
    $c->stash->{$key}{object} = {$c->req->get_chained_object(-1)->[0]->get_columns};
    $c->stash->{$key}{id}     = $c->stash->{$key}{object}{id};
}


=head2 private_object

Currently does nothing.

=cut

sub private_object {}


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


# stolen / modified from Catalyst::Controller::DBIC::API

=begin Pod::Coverage

 delete
 delete_object
 delete_objects
 each_object_inflate
 generate_rs
 inflate_request
 insert_object_from_params
 item
 list_format_output
 list_munge_parameters
 list_perform_search
 object_lookup
 row_format_output
 save_object
 save_objects
 transact_objects
 update_object_from_params
 update_object_relation
 update_or_create
 validate_object
 validate_objects

=end Pod::Coverage

=cut

sub generate_rs {
    my ($self, $c) = @_;
    return $c->model($self->class);
}

sub inflate_request {
    my ($self, $c, $params) = @_;

    try {
        # set static arguments
        $c->req->_set_controller($self);

        # set request arguments
        $c->req->_set_request_data($params);

        # set the current resultset
        $c->req->_set_current_result_set($self->generate_rs($c));
    }
    catch {
        $c->log->error($_);
        $c->error($_);
        $c->detach();
    };
}

sub object_lookup {
    my ($self, $c, $id) = @_;

    die 'No valid ID provided for look up' unless defined $id and length $id;
    my $object = $c->req->current_result_set->find($id);
    die "No object found for id '$id'" unless defined $object;
    return $object;
}

sub list_munge_parameters { }   # noop by default

sub list_perform_search {
    my ($self, $c) = @_;

    try {
        my $req = $c->req;

        my $rs = $req->current_result_set->search(
            $req->search_parameters,
            $req->search_attributes
        );

        $req->_set_current_result_set($rs);

        $req->_set_search_total_entries($req->current_result_set->pager->total_entries)
            if $req->has_search_attributes && (exists($req->search_attributes->{page}) && defined($req->search_attributes->{page}) && length($req->search_attributes->{page}));
    }
    catch {
        $c->log->error($_);
        $c->error('a database error has occured.');
        $c->detach();
    };
}

sub list_format_output {
    my ($self, $c) = @_;

    my $rs = $c->req->current_result_set->search;
    $rs->result_class($self->result_class) if $self->result_class;

    try {
        my $output = {};
        my $formatted = [];

        foreach my $row ($rs->all) {
            push(@$formatted, $self->row_format_output($c, $row));
        }

        $output->{$self->data_root} = $formatted;

        if ($c->req->has_search_total_entries) {
            $output->{$self->total_entries_arg} = $c->req->search_total_entries + 0;
        }

        $c->stash->{$self->stash_key} = $output;
    }
    catch {
        $c->log->error($_);
        $c->error('a database error has occured.');
        $c->detach();
    };
}

sub row_format_output {
    my ($self, undef, $row) = @_;
    return $row;            # passthrough by default
}

sub item {
    my ($self, $c) = @_;

    if ($c->req->count_objects != 1) {
        $c->log->error($_);
        $c->error('No objects on which to operate');
        $c->detach();
    }
    else {
        $c->stash->{$self->stash_key}->{$self->item_root}
            = $self->each_object_inflate($c, $c->req->get_object(0)->[0]);
    }
}

sub update_or_create {
    my ($self, $c) = @_;

    if ($c->req->has_objects) {
        $self->validate_objects($c);
        $self->transact_objects($c, sub { $self->save_objects($c, @_) } );
    }
    else {
        $c->log->error($_);
        $c->error('No objects on which to operate');
        $c->detach();
    }
}

sub transact_objects {
    my ($self, $c, $coderef) = @_;

    try {
        $self->stored_result_source->schema->txn_do(
            $coderef,
            $c->req->objects
        );
    }
    catch {
        $c->log->error($_);
        $c->error('a database error has occured.');
        $c->detach();
    };
}

sub validate_objects {
    my ($self, $c) = @_;

    try {
        foreach my $obj ($c->req->all_objects) {
            $obj->[1] = $self->validate_object($c, $obj);
        }
    }
    catch {
        my $err = $_;
        $c->log->error($err);
        $err =~ s/\s+at\s+.+\n$//g;
        $c->error($err);
        $c->detach();
    };
}

sub validate_object {
    my ($self, $c, $obj) = @_;
    my ($object, $params) = @$obj;

    my %values;
    my %requires_map = map {$_ => 1} @{
        ($object->in_storage)
            ? []
                : $c->stash->{create_requires} || $self->create_requires
    };

    my %allows_map = map { (ref $_) ? %{$_} : ($_ => 1) } (
        keys %requires_map,
        @{
            ($object->in_storage)
                ? ($c->stash->{update_allows} || $self->update_allows)
                    : ($c->stash->{create_allows} || $self->create_allows)
                }
    );

    foreach my $key (keys %allows_map) {
        # check value defined if key required
        my $allowed_fields = $allows_map{$key};

        if (ref $allowed_fields) {
            my $related_source = $object->result_source->related_source($key);
            my $related_params = $params->{$key};
            my %allowed_related_map = map { $_ => 1 } @$allowed_fields;
            my $allowed_related_cols = ($allowed_related_map{'*'})
                ? [$related_source->columns]
                : $allowed_fields;

            foreach my $related_col (@{$allowed_related_cols}) {
                if (defined(my $related_col_value = $related_params->{$related_col})) {
                    $values{$key}{$related_col} = $related_col_value;
                }
            }
        }
        else {
            my $value = $params->{$key};

            if ($requires_map{$key}) {
                unless (defined($value)) {
                    # if not defined look for default
                    $value = $object->result_source->column_info($key)->{default_value};
                    unless (defined $value) {
                        die "No value supplied for ${key} and no default";
                    }
                }
            }

            # check for multiple values
            if (ref($value) && !(reftype($value) eq reftype(JSON::true))) {
                require Data::Dumper;
                die "Multiple values for '${key}': ${\Data::Dumper::Dumper($value)}";
            }

            # check exists so we don't just end up with hash of undefs
            # check defined to account for default values being used
            $values{$key} = $value if exists $params->{$key} || defined $value;
        }
    }

    unless (keys %values || !$object->in_storage) {
        die 'No valid keys passed';
    }

    return \%values;
}

sub delete {
    my ($self, $c) = @_;

    if ($c->req->has_objects) {
        $self->transact_objects($c, sub { $self->delete_objects($c, @_) });
        $c->req->clear_objects;
    }
    else {
        $c->log->error($_);
        $c->error('No objects on which to operate');
        $c->detach();
    }
}

sub save_objects {
    my ($self, $c, $objects) = @_;

    foreach my $obj (@$objects) {
        $self->save_object($c, $obj);
    }
}

sub save_object {
    my ($self, $c, $obj) = @_;

    my ($object, $params) = @$obj;
    if ($object->in_storage) {
        $self->update_object_from_params($c, $object, $params);
    }
    else {
        $self->insert_object_from_params($c, $object, $params);
    }

}

sub update_object_from_params {
    my ($self, $c, $object, $params) = @_;

    foreach my $key (keys %$params) {
        my $value = $params->{$key};
        if (ref($value) && !(reftype($value) eq reftype(JSON::true))) {
            $self->update_object_relation($c, $object, delete $params->{$key}, $key);
        }
        # accessor = colname
        elsif ($object->can($key)) {
            $object->$key($value);
        }
        # accessor != colname
        else {
            my $accessor = $object->result_source->column_info($key)->{accessor};
            $object->$accessor($value);
        }
    }

    $object->update();
}

sub update_object_relation {
    my ($self, $c, $object, $related_params, $relation) = @_;
    my $row = $object->find_related($relation, {} , {});

    if ($row) {
        foreach my $key (keys %$related_params) {
            my $value = $related_params->{$key};
            if (ref($value) && !(reftype($value) eq reftype(JSON::true))) {
                $self->update_object_relation($c, $row, delete $related_params->{$key}, $key);
            }
            # accessor = colname
            elsif ($row->can($key)) {
                $row->$key($value);
            }
            # accessor != colname
            else {
                my $accessor = $row->result_source->column_info($key)->{accessor};
                $row->$accessor($value);
            }
        }
        $row->update();
    }
    else {
        $object->create_related($relation, $related_params);
    }
}

sub insert_object_from_params {
    my ($self, undef, $object, $params) = @_;

    my %rels;
    while (my ($key, $value) = each %{ $params }) {
        if (ref($value) && !(reftype($value) eq reftype(JSON::true))) {
            $rels{$key} = $value;
        }
        # accessor = colname
        elsif ($object->can($key)) {
            $object->$key($value);
        }
        # accessor != colname
        else {
            my $accessor = $object->result_source->column_info($key)->{accessor};
            $object->$accessor($value);
        }
    }

    $object->insert;

    while (my ($k, $v) = each %rels) {
        $object->create_related($k, $v);
    }
}

sub delete_objects {
    my ($self, $c, $objects) = @_;
    map { $self->delete_object($c, $_->[0]) } @$objects;
}

sub delete_object {
    my ($self, undef, $object) = @_;
    $object->delete;
}

sub each_object_inflate {
    my ($self, undef, $object) = @_;
    return { $object->get_columns };
}




__PACKAGE__->meta->make_immutable;

1;
__END__
