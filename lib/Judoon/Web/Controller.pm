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

BEGIN { extends 'Catalyst::Controller::ActionRole'; }

use Safe::Isa;


__PACKAGE__->config(
   action => {
      '*' => { Does => 'DetachOnDie' },
   },
);


=head1 METHODS

=head2 handle_error( $c, $error, \%args )

This method encapsulates common error-handling logic for
L<Judoon::Web> controllers.  If the given error does the
L<Judoon::Error> role, then it's assumed to be recoverable and the
error message is stuffed into the flash and and the user is redirect
to the action in C<$args->{redir_to}>.

If the given error is not a C<Judoon::Error>, it is added the the
Catalyst error list, which will casue the Catalyst error screen to be
displayed.

This action detaches when done.

=cut

sub handle_error :Private {
    my ($self, $c, $error, $args) = @_;

    if ( $error->$_DOES('Judoon::Error') ) {
        $self->set_error_and_redirect(
            $c, $error->message, $args->{redir_to}
        );
    }
    else {
        $c->error($error);
    }

    $c->detach();
}


=head2 set_error_and_redirect( $c, $errmsg, \@action )

Sets the flash to C<$errmsg> and redirects to the action given by
C<\@action>, where C<\@action> is an arrayref of args suitable for
passing to C<< $c->uri_for_action >>.

=cut

sub set_error_and_redirect {
    my ($self, $c, $error, $action_ar) = @_;
    $c->flash->{alert}{error} = $error;
    $c->res->redirect( $c->uri_for_action( @$action_ar ) );
}

__PACKAGE__->meta->make_immutable;

1;
__END__
