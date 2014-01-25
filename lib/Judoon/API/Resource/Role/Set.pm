package Judoon::API::Resource::Role::Set;

=pod

=encoding utf8

=head1 NAME

Judoon::API::Resource::Role::Set - Role for a set of a given Resource

=head1 DESCRIPTION

This role is intended to be consumed by endpoints representing a set
of resources (e.g. /api/dataset).  It provides the default actions the
Resource (an instance of L</Web::Machine::Resource>) is expected to
provide.

=head1 SYNOPSIS

 package Judoon::API::Resource::Datasets;

 use Moo;

 extends 'Web::Machine::Resource';
 with 'Judoon::Role::JsonEncoder';
 with 'Judoon::API::Resource::Role::Set';

 1;

=cut

use Safe::Isa;

use Moo::Role;


requires 'decode_json';
requires 'encode_json';


=head1 ATTRIBUTES

=head2 set

Required.  A L<Judoon::Schema> ResultSet.

=cut

has set => (
    is       => 'ro',
    required => 1,
);

=head2 writable

Indicates whether this resource can be modified.

=cut

has writable => (is => 'ro',);

=head2 is_authorized / forbidden

Let external code decide when 401 or 403 should be returned.

=cut

has forbidden => (is => 'ro', default => 0);
has is_authorized => (is => 'ro', default => 1);

=head2 obj

Stores a new object created by a POST action so that we can get its id
to construct a URL later.

=cut

has obj => (is => 'rw', writer => '_set_obj');


=head1 METHODS FROM Web::Machine::Resource

=head2 allowed_methods

Permitted HTTP verbs.  GET and HEAD are always available.  POST and
DELETE are available when the C<writable> attribute is set.

=cut

sub allowed_methods {
    return [
        qw(GET HEAD),
        ( $_[0]->writable ) ? (qw(POST DELETE)) : ()
    ];
}


=head2 content_types_provided / content_types_accepted

Map content types to translation methods.

=cut

sub content_types_provided { [ {'application/json' => 'to_json'} ] }
sub content_types_accepted { [ {'application/json' => 'from_json'} ] }


=head2 to_json / from_json

Turn JSON into objects and vice-versa.

=cut

sub to_json {
    my $self = shift;
    $self->encode_json([ map $self->render_item($_), $self->set->all ])
}

sub from_json {
    my ($self) = @_;
    my $content = $self->request->content;
    my $obj = $self->create_resource(
        $self->decode_json( $content )
    );
    $self->_set_obj($obj);
}


=head2 post_is_create / create_path / create_path_after_handler

A POST to our resource creates a new instance of that resource.  We
need to be able to construct a URL to that new resource, so don't
build the URL until after the object is inserted.  The path to the new
resource is the current url + the resource id.

=cut

sub post_is_create { 1 }
sub create_path { $_[0]->obj->$_call_if_object('id'); }
sub create_path_after_handler { 1 }


=head2 create_resource

Create a new resource as a member of C<set>.

=cut

sub create_resource { $_[0]->set->create($_[1]) }


=head2 delete_resource

Delete all members of C<set>.

=cut

sub delete_resource { $_[0]->set->delete; }


=head1 OUR METHODS

=head2 render_item

Turns each member of C<set> into JSON.

=cut

sub render_item { $_[1]->TO_JSON; }


1;

=head1 AUTHOR

Fitz ELLIOTT <felliott@fiskur.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by the Rector and Visitors of the
University of Virginia.

This is free software, licensed under:

 The Artistic License 2.0 (GPL Compatible)

=cut
