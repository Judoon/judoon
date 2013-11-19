package Plack::Middleware::LocationToRedirect;

use strict;
use 5.008001;

use parent qw(Plack::Middleware);
use Plack::Response;
use Plack::Util::Accessor qw( process_location );
use Plack::Util;

use List::Util ();

sub call {
    my($self, $env) = @_;

    my $res = $self->app->($env);

    $self->response_cb($res, sub {
        my $res = shift;

        my $h = Plack::Util::headers($res->[1]);
        my $location = $h->get('Location');
        return unless ($res->[0] == 201 && $location);

        # JSON requests pass through just fine
        return if ($env->{HTTP_ACCEPT} =~ m{application/json});

        my $new_loc  = $self->process_location->( $env, $location );
        my $response = Plack::Response->new;
        $response->redirect( $new_loc );
        @$res = @{$response->finalize};
    });
}


1;
__END__
