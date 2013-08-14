package Judoon::Web::Controller::API::Types;

use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller::REST'; }

__PACKAGE__->config(
    default => 'application/json',
    'map' => {
        'application/json' => 'JSON',
        'text/html' => 'YAML::HTML',
    },
);


sub base : Chained('/api/base') PathPart('datatype') CaptureArgs(0) {}
sub index : Chained('base') PathPart('') Args(0) ActionClass('REST') {}
sub index_GET {
    my ($self, $c) = @_;
    my $typereg = $c->model('TypeRegistry');
    $self->status_ok($c, entity => [
        map {$typereg->simple_lookup($_)->TO_JSON}
            sort $typereg->all_types
    ]);
}


sub type_id : Chained('base') PathPart('') CaptureArgs(1) {
    my ($self, $c, $type_id) = @_;

    $type_id //= '';
    $c->stash->{type_id} = $type_id;
    my $type = $c->model('TypeRegistry')->simple_lookup($type_id);

    if (not $type) {
        $self->status_not_found(
            $c, message => qq{No such type "$type_id"},
        );
        $c->detach();
    }
    $c->stash->{type} = $type->TO_JSON;
}
sub type : Chained('type_id') PathPart('') Args(0)  ActionClass('REST') {}
sub type_GET {
    my ($self, $c) = @_;
    $self->status_ok( $c, entity => $c->stash->{type}, );
}


__PACKAGE__->meta->make_immutable;
1;
__END__

=pod

=encoding utf8

=head1 NAME

Judoon::Web::Controller::API::Types - API for our Type classes

=head1 ACTIONS

=head2 base

Base action for common actions. Currently does nothing.

=head2 index / index_GET

Return a serialized list of types.

=head2 type_id

Lookup the given type, returning 404 if not found.

=head2 type / type_GET

Return the serialized type.

=cut



