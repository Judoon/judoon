package Judoon::API::Resource::Role::Set;

use Moo::Role;

use Safe::Isa;

requires 'decode_json';
requires 'encode_json';


has set => (
    is       => 'ro',
    required => 1,
);

has writable => (
   is => 'ro',
);

sub allowed_methods {
   [
      qw(GET HEAD),
      ( $_[0]->writable ) ? (qw(POST PUT DELETE)) : ()
   ]
}


has obj => (is => 'rw', writer => '_set_obj');
sub post_is_create { 1 }
sub create_path { $_[0]->obj->$_call_if_object('id'); }
sub create_path_after_handler { 1 }

sub content_types_provided { [ {'application/json' => 'to_json'} ] }
sub content_types_accepted { [ {'application/json' => 'from_json'} ] }

sub to_json {
    my $self = shift;
    $self->encode_json([ map $self->render_item($_), $self->set->all ])
}
sub render_item { $_[1]->TO_JSON; }

sub from_json {
    my ($self) = @_;
    $self->request->env->{'psgix.input.buffered'} = 1;
    my $content = $self->request->content;
    my $obj = $self->create_resource(
        $self->decode_json(
            $content
        )
    );
    $self->_set_obj($obj);
}

sub create_resource { $_[0]->set->create($_[1]) }

1;
