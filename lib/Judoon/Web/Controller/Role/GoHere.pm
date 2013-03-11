package Judoon::Web::Controller::Role::GoHere;

use Moose::Role;
use namespace::autoclean;

use Judoon::Error::Devel::Arguments;

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
      : Judoon::Error::Devel::Arguments->throw({
          message  => q{go_here() doesn't handle complicated arguments},
          got      => (!defined($arg) ? 'undef' : ref($arg)),
          expected => 'arrayref or hashref',
      });
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

1;
__END__
