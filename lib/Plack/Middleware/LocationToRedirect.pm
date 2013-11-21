package Plack::Middleware::LocationToRedirect;

use strict;
use warnings;

use parent qw(Plack::Middleware);
use Plack::Util::Accessor qw( process_location );
use Plack::Util ();
use HTTP::Headers::ActionPack::LinkHeader;

sub call {
    my ($self, $env) = @_;
    $self->response_cb($self->app->($env), sub {
        my $res = shift;

        my $h = Plack::Util::headers($res->[1]);
        my $link_header = $h->get('Link');
        return unless ($res->[0] == 201 && $link_header);

        # JSON requests pass through just fine
        return if ($env->{HTTP_ACCEPT} =~ m{application/json});

        my $link = HTTP::Headers::ActionPack::LinkHeader->new_from_string(
            $link_header
        );
        my $new_loc = $self->process_location->( $env, $link->href );
        $h->set('Location', $new_loc);
        $res->[0] = 302;
        return;
    });
}


1;
__END__
