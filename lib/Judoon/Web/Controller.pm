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


__PACKAGE__->config(
   action => {
      '*' => { Does => 'DetachOnDie' },
   },
);

use Judoon::Error;

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
