package Judoon::Web::Controller;

use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

sub go_relative {
    my ($self, $c, $action_path, $captures) = @_;
    my $action = $c->controller->action_for($action_path);
    $self->go_here($c, $action, $captures);
}

sub go_here {
    my ($self, $c, $action, $captures) = @_;
    $c->res->redirect($c->uri_for_action($action, $captures));
}

sub push_path {
    my ($self, $c, $action, $captures) = @_;
    my $current_captures = $c->req->captures;
    push @$current_captures, $captures;
    $self->go_here($c, $action, $captures);
}

sub pop_path {
    my ($self, $c) = @_;
    my $captures = $c->req->captures;
    pop @$captures;
}


__PACKAGE__->meta->make_immutable;

1;
__END__
