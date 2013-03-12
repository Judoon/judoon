package Judoon::Web::Controller;

=pod

=encoding utf8

=head1 NAME

Judoon::Web::Controller - base controller for Judoon

=head1 SYNOPSIS

 BEGIN { extends 'Judoon::Web::Controller'; }

=head1 DESCRIPTION

This provides common utility methods for Judoon::Web controllers.

=cut

use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller::ActionRole'; }

use Safe::Isa;


# use ActionRole::DetachOnDie, so we don't keep running though the
# action chain after a die.
__PACKAGE__->config(
   action => {
      '*' => { Does => 'DetachOnDie' },
   },
);


=head1 METHODS

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
