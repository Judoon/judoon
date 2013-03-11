package Judoon::Web::Controller::Role::GoHere;

=pod

=encoding utf8

=head1 NAME

Judoon::Web::Controller::Role::GoHere - redirect shortcuts

=head1 SYNOPSIS

 package Judoon::Web::Controller::User;
 with 'Judoon::Web::Controller::Role::GoHere';

 sub add {
    my ($self, $c) = @_;
    # ...add new user...
    if ($newuser) {
        # redirects to /user/$id/edit
        $self->go_relative($c, 'edit', [$new_user->id]);
    }
    else {
        $self->go_here($c, '/signup');
    }
 }

=head1 DESCRIPTION

C<Judoon::Web::Controller::Role::GoHere> provides two shortcut methods
for creating redirect responses.

 $self->go_here($c, '/signup');

is equivalent to:

 $c->response->redirect(
     $c->uri_for_action('/signup')
 );

and:

 $self->go_relative($c, 'edit', [$newuser->id]);

is equivalent to:

 $c->response->redirect(
     $c->uri_for_action(
         $c->controller->action_for('edit'),
         [$newuser->id],
     )
 );

=cut


use Moose::Role;
use namespace::autoclean;

use Judoon::Error::Devel::Arguments;

=head1 METHODS

=head2 go_here($c, $action, \@captures?, \%query?)

C<go_here()> is an alias for:

 $c->res->redirect($c->uri_for_action($action, \@captures, \%query))

except C<\@captures> defaults to C<< $c->req->captures >>, and
C<\%query> defaults to C<< $c->req->query_params >>.  If you want to
redirect to a url without captures from an action with them, you must
explicitly pass an empty arrayref as the C<\@captures> argument, and
likewise with C<\%query>.

=cut

sub go_here {
    my ($self, $c, $action, @args) = @_;
    my ($captures, $query);
    for my $arg (@args) {
        ref $arg eq 'ARRAY' ? $captures = $arg
      : ref $arg eq 'HASH'  ? $query    = $arg
      : Judoon::Error::Devel::Arguments->throw({
          message  => q{arguments to go_here() should be captures or query params},
          got      => (!defined($arg) ? 'undef' : ref($arg)),
          expected => 'arrayref or hashref',
      });
    }
    $captures //= $c->req->captures;
    $query    //= $c->req->query_params;
    $c->res->redirect($c->uri_for_action($action, $captures, $query));
}


=head2 go_relative($c, $action, \@captures?, \%query?)

C<go_relative()> is like L</go_here()>, except C<$action> is assumed
to be an action in the current controller, and therefore doesn't need
the full action path.

 # if current controller is ::User, this goes to /user/add
 $c->go_relative('add', $captures);

This method calls L</go_here> with the C<$action> argument replaced
with the result of C<< $c->controller->action_for($action) >>. The C<<
\@captures >> and C<< \%query >> are passed unmodifed.

=cut

sub go_relative {
    my ($self, $c, $action_path, @args) = @_;
    my $action = $c->controller->action_for($action_path);
    $self->go_here($c, $action, @args);
}


1;
__END__
