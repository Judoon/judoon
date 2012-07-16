package Judoon::Web::Controller;

=pod

=encoding utf8

=head1 NAME

Judoon::Web::Controller - base controller for Judoon

=head1 SYNOPSIS

 BEGIN { extends 'Judoon::Web::Controller'; }

=head1 DESCRIPTION

This provides common utility methods for Judoon

=cut

use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }


=head2 B<C<go_here($c, $action, \@captures?, \%query?)>>

C<go_here()> is an alias for:

 $c->res->redirect($c->uri_for_action($action, \@captures, \%query))

except C<\@captures> defaults to C<< $c->req->captures >>, and
C<\%query> defaults to C<< $c->req->query_params >>.

=cut

sub go_here {
    my ($self, $c, $action, @args) = @_;
    my ($captures, $query);
    for my $arg (@args) {
        ref $arg eq 'ARRAY' ? $captures = $arg
      : ref $arg eq 'HASH'  ? $query    = $arg
      : die q{go_here() doesn't handle complicated arguments};
    }
    $captures //= $c->req->captures;
    $query    //= $c->req->query_params;
    $c->res->redirect($c->uri_for_action($action, $captures, $query));
}


=head2 B<C<go_relative($c, $action, \@captures?, \%query?)>>

C<go_relative()> is like L</go_here()>, except C<$action> is assumed
to be an action in the current controller, and therefore doesn't need
the full action path.

 # if current controller is ::User, this goes to /user/add
 $c->go_relative('add', $captures);

=cut

sub go_relative {
    my ($self, $c, $action_path, @args) = @_;
    my $action = $c->controller->action_for($action_path);
    $self->go_here($c, $action, @args);
}


=head2 B<C<push_path($c, $action, \@captures, \%query?)>>

C<push_path> pushes \@captures onto the current list of captures, then
proceeds to C<$action>.

=cut

sub push_path {
    my ($self, $c, $action, $captures, @args) = @_;
    my $current_captures = $c->req->captures;
    push @$current_captures, $captures;
    $self->go_here($c, $action, $captures, @args);
}


=head2 B<C<pop_path($c, $action, \%query?)>>

C<pop_path> pops C<< $c->req->captures >>, then proceeds to
C<$action>.

=cut

sub pop_path {
    my ($self, $c, $action, @args) = @_;
    my $captures = $c->req->captures;
    pop @$captures;
    $self->go_here($c, $action, $captures, @args);
}


__PACKAGE__->meta->make_immutable;

1;
__END__
