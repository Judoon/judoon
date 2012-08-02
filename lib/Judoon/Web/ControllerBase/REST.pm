package Judoon::Web::ControllerBase::REST;

=pod

=encoding utf8

=head1 NAME

Judoon::Web:ControllerBase::REST - base class for our DBIC::API controllers

=head1 SYNOPSIS

 package Judoon::Web::Controller::API::REST::Something;
 use Moose;
 BEGIN { extends 'Judoon::Web:ControllerBase::REST'; }
 1;

=head1 DESCRIPTION

This is the base class for all of our API controllers.  Here we
override the undesirable behavoirs in Catalyst::Controller::DBIC::API.

=cut

use Moose;
use MooseX::Types::Moose(':all');
use namespace::autoclean;

BEGIN { extends qw/Catalyst::Controller::DBIC::API::REST/; }
use Catalyst::Controller::DBIC::API::Request::Chained;

has stash_namespace => (is => 'ro', isa => Str, required => 1,);

after begin => sub {
    my ($self, $c) = @_;
    Catalyst::Controller::DBIC::API::Request::Chained->meta->apply($c->req)
        unless Moose::Util::does_role($c->req, 'Catalyst::Controller::DBIC::API::Request::Chained');
};

sub chainpoint :Chained('object_with_id') PathPart('') CaptureArgs(0) {
    my ($self, $c) = @_;

    if ($c->req->count_objects != 1) {
        $c->log->error('No object to chain from!');
        $self->push_error($c, { message => 'No object to chain from!' });
        $c->detach();
    }

    my $object = $c->req->get_object(0);
    $c->req->add_chained_object($object);
    $c->req->clear_objects();
}

around update_or_create => sub {
    my $orig = shift;
    my $self = shift;
    my $c    = shift;

    $self->$orig($c, @_);
    if ($c->stash->{created_object}) {
        %{$c->stash->{response}->{new_object}} = $c->stash->{created_object}->get_columns;
    }
};


__PACKAGE__->meta->make_immutable;
1;
