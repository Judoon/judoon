package Judoon::Web::ControllerBase::REST;

use Moose;
use namespace::autoclean;

BEGIN { extends qw/Catalyst::Controller::DBIC::API::REST/; }

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
