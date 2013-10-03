package Judoon::API::Resource::Role::Item;

=pod

=encoding utf8

=head1 NAME

Judoon::API::Resource::Role::Item - Role for one of a given Resource

=head1 DESCRIPTION

This role is intended to be consumed by endpoints representing
individual resources (e.g. /api/dataset/1).  It provides the default
actions the Resource (an instance of L</Web::Machine::Resource>) is
expected to provide.

=head1 SYNOPSIS

 package Judoon::API::Resource::Dataset;

 use Moo;

 extends 'Web::Machine::Resource';
 with 'Judoon::Role::JsonEncoder';
 with 'Judoon::API::Resource::Role::Item';

 1;

=cut

use Moo::Role;

requires 'encode_json';
requires 'decode_json';


=head1 ATTRIBUTES

=head2 item

Required.  A L<Judoon::Schema> row object.

=cut

has item => (
    is       => 'ro',
    required => 1,
);

=head2 writable

Indicates whether this resource can be modified.

=cut

has writable => (is => 'ro',);


=head1 METHODS FROM Web::Machine::Resource

=head2 allowed_methods

Permitted HTTP verbs.  GET and HEAD are always available.  PUT and
DELETE are available when the C<writable> attribute is set.

=cut

sub allowed_methods {
   return [
      qw(GET HEAD),
      ( $_[0]->writable ) ? (qw(PUT DELETE)) : ()
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

sub to_json { $_[0]->encode_json($_[0]->render_item(($_[0]->item))) }
sub from_json {
    my ($self) = @_;
    my $content = $self->request->content;
    $self->update_resource(
        $self->decode_json( $content )
    );
}


=head2 resource_exists

If the C<item> attribute is set, our resource exists.

=cut

sub resource_exists { !! $_[0]->item }


=head2 update_resource / delete_resource

Update / delete the specific resource stored in C<item>.

=cut

sub update_resource { $_[0]->item->update($_[1]) }

sub delete_resource { $_[0]->item->delete }



=head1 OUR METHODS

=head2 render_item

Turns C<item> into JSON.

=cut

sub render_item { return $_[1]->TO_JSON; }


1;
