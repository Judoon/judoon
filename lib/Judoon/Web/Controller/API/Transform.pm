package Judoon::Web::Controller::API::Transform;

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


use Module::Load;


sub base : Chained('/api/base') PathPart('transform') CaptureArgs(0) {}
sub index : Chained('base') PathPart('') Args(0) ActionClass('REST') {}
sub index_GET {
    my ($self, $c) = @_;
    $self->status_ok($c, entity => $c->model('TransformRegistry')->type_list);
}


sub type_id : Chained('base') PathPart('') CaptureArgs(1) {
    my ($self, $c, $type_id) = @_;

    $type_id //= '';
    $c->stash->{type_id} = $type_id;
    $c->stash->{transform_list}
        = $c->model('TransformRegistry')->transforms_for($type_id);

    if (not $c->stash->{transform_list}) {
        $self->status_not_found(
            $c, message => qq{No such type "$type_id"},
        );
        $c->detach();
    }
}
sub type : Chained('type_id') PathPart('') Args(0)  ActionClass('REST') {}
sub type_GET {
    my ($self, $c) = @_;
    $self->status_ok( $c, entity => $c->stash->{transform_list}, );
}


sub transform_id : Chained('type_id') PathPart('') CaptureArgs(1) {
    my ($self, $c, $transform_id) = @_;

    $transform_id //= '';
    $c->stash->{transform_id} = $transform_id;
    $c->stash->{transform} = $c->model('TransformRegistry')
        ->transform($c->stash->{type_id}, $transform_id);

    if (not $c->stash->{transform}) {
        $self->status_not_found(
            $c, message => qq{No such transform named "$transform_id" found}
        );
        $c->detach();
    }
}
sub transform : Chained('transform_id') PathPart('') Args(0) ActionClass('REST') {}
sub transform_GET {
    my ($self, $c) = @_;
    $self->status_ok( $c, entity => $c->stash->{transform} );
}
sub transform_POST {
    my ($self, $c) = @_;

    my $params = $c->req->data;
    $params->{data} //= [];
    use Data::Printer;
    $c->log->debug("Data is: " . p($params));
    if (not @{ $params->{data} } ) {
        $self->status_bad_request($c, message => 'No data to operate on!');
        $c->detach();
    }

    # url:  /api/transform/text/lowercase
    # data: [qw(WHEE MOO QUack!)]
    # ----
    # res:  [qw(whee moo quack!)]

    # url:  /api/transform/lookup/uniprot
    # data: [qw(Fbgn01 Fbgn02 Fbgn03)]
    # from: FlybaseID
    # to:   UniprotKB ACC
    # ----
    # res:  [qw(P123 Q456 P789)]

    # url:      /api/transform/lookup/judoon
    # data:     [qw(moo quack grr)]
    # from_ds:  DerpDS
    # from_col: FooColumn
    # to_ds:    HerpDS
    # to_col:   BarColumn
    # join_col: BazColumn
    # ----
    # res:      [map {to_ds_2_col_bar($_)} @$data]

    # method: GET
    # url:    /api/transform/lookup/join_table
    #   get


    my $module = $c->stash->{transform}{module};

    if ($module !~ m/^\+/) {
        $module = "Judoon::Transform::$module";
    }

    load $module;
    my $transformer;
    try {
        $transformer = $module->new( $params );
    }
    catch {
        my $e = $_;
        $self->status_bad_request(
            $c, message => 'Missing params: ' . $e->missing
        );
        # if not $e->does('missing') ?
        $c->detach();
    };

    my $trans_data = $transformer->apply( $params->{data} );
    $self->status_ok(
        $c, entity => { data => $trans_data },
    );
}



__PACKAGE__->meta->make_immutable;
1;
