package Judoon::API::Resource::Role::Item;

use Moo::Role;

requires 'encode_json';
requires 'decode_json';

has item => (
    is       => 'ro',
    required => 1,
);

has writable => (
   is => 'ro',
);

sub content_types_provided { [ {'application/json' => 'to_json'} ] }
sub content_types_accepted { [ {'application/json' => 'from_json'} ] }

sub to_json { $_[0]->encode_json($_[0]->render_item(($_[0]->item))) }
sub render_item { return $_[1]->TO_JSON; }

sub from_json {
    my ($self) = @_;
    $self->request->env->{'psgix.input.buffered'} = 1;
    my $content = $self->request->content;
    $self->update_resource(
        $self->decode_json(
            $content
        )
    )
}

sub resource_exists { !! $_[0]->item }

sub allowed_methods {
   [
      qw(GET HEAD),
      ( $_[0]->writable || 1 ) ? (qw(PUT DELETE)) : ()
   ]
}

sub delete_resource { $_[0]->item->delete }

sub update_resource { $_[0]->item->update($_[1]) }

1;
