package Judoon::API::Resource;

=pod

=encoding utf8

=head1 NAME

Judoon::API:Resource - base class for our Web::Machine resources

=head1 DESCRIPTION

This package provides behavior common to all Judoon::API::Resource::*
classes.  Specifically, it currently handles exceptions thrown via
L</HTTP::Throwable::Factory>'s C<http_throw()> method.  It catches
these exceptions and sets the response status and body.  Other types
of errors are ignored.

=cut

use Safe::Isa;

use Moo;
use namespace::clean;

extends 'Web::Machine::Resource';

=head1 METHODS

=head2 finish_request() (override)

Overrides the C<finish_request()> method of L</Web::Machine::Resource>
to handle L</HTTP::Throwable> exceptions.

=cut

sub finish_request {
    my ($self, $metadata) = @_;
    if (my $e = $metadata->{exception}) {
        if ($e->$_DOES('HTTP::Throwable')) {
            $self->response->status( $e->status_code );
            $self->response->body( $e->as_string );
        }
    }
}



1;
__END__

=head1 AUTHOR

Fitz ELLIOTT <felliott@fiskur.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by the Rector and Visitors of the
University of Virginia.

This is free software, licensed under:

 The Artistic License 2.0 (GPL Compatible)

=cut
