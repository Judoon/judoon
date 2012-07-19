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

use Judoon::Error;

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


sub handle_error :Private {
    my ($self, $c, $error) = @_;
    if (not ref $error) {
        Judoon::Error->throw({message => $error, recoverable => 0});
    }
    elsif (not $error->recoverable) {
        $error->throw;
    }
    else {
        $c->stash->{alert}{error} = $error->message;
    }
}

__PACKAGE__->meta->make_immutable;

1;
__END__
