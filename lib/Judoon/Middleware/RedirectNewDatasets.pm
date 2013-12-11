package Judoon::Middleware::RedirectNewDatasets;

use strict;
use warnings;

use parent qw(Plack::Middleware);
use Plack::Util ();
use HTTP::Headers::ActionPack::LinkHeader;

sub call {
    my ($self, $env) = @_;
    $self->response_cb($self->app->($env), sub {
        my $res = shift;

        # JSON requests (i.e. data) requests pass through just fine
        return if ($env->{HTTP_ACCEPT} =~ m{application/json});

        my $h = Plack::Util::headers($res->[1]);

        # redirect 500s to a better-looking error page
        if ($res->[0] == 500) {
            $h->set('Location', '/error');
            $res->[0] = 302;
            return;
        }

        # only modify the repsonse if status is 201 and there's a Link header
        my $link_header = $h->get('Link');
        return unless ($res->[0] == 201 && $link_header);
        my $link = HTTP::Headers::ActionPack::LinkHeader->new_from_string(
            $link_header
        );

        my ($page_id) = ($link->href =~ m/(\d+)$/);
        my $new_loc   = $env->{HTTP_REFERER} . "/page/$page_id";
        my $host      = $env->{HTTP_HOST};
        $new_loc      =~ s{^http.?://$host}{};
        $new_loc      .= '?welcome=1';
        $h->set('Location', $new_loc);
        $res->[0] = 302;

        return;
    });
}


1;
__END__

=pod

=encoding utf8

=head1 NAME

Judoon::Middleware::RedirectNewDatasets - after adding dataset, send users to default view

=head1 DESCRIPTION

This module is a ugly-but-easy hack to facilitate the web interface.
After a user uploads a new dataset, the API responds with a 201
Accepted status code, and a Location header that points to the
location of the new dataset.  This is great for API users, but web
users should be sent to the default page created for every new dataset.

To facilitate this the API sets a Link header that points to the new
page's URL.  This middleware looks for that header, and if found,
mutates the response into a 302 redirect to the new page's web URL.

=head1 Methods

=head2 call

Implements the response inspection and mutation.

=cut
