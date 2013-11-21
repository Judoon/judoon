package Plack::Middleware::LocationToRedirect;

use strict;
use warnings;

use parent qw(Plack::Middleware);
use Plack::Util::Accessor qw( process_location );
use Plack::Util ();

sub call {
    my ($self, $env) = @_;
    $self->response_cb($self->app->($env), sub {
        my $res = shift;

        my $h = Plack::Util::headers($res->[1]);
        my $location = $h->get('Location');
        return unless ($res->[0] == 201 && $location);

        # JSON requests pass through just fine
        return if ($env->{HTTP_ACCEPT} =~ m{application/json});

        my $new_loc = $self->process_location->( $env, $location );
        $h->set('Location', $new_loc);
        $res->[0] = 302;
        return;
    });
}


1;
__END__
