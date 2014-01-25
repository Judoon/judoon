package HTTP::Throwable::Role::Status::UnprocessableEntity;
use Moose::Role;

with(
    'HTTP::Throwable',
    'HTTP::Throwable::Role::BoringText',
);

sub default_status_code { 422 }
sub default_reason { 'Unprocessable Entity' }

no Moose::Role; 1;

__END__

=pod

=head1 NAME

HTTP::Throwable::Role::Status::UnprocessableEntity - 422 Unprocessable Entity

=head1 DESCRIPTION

This exception provides support for the 422 Unprocessable Entity
status code, as outlined in RFC4218 support in accordance with
section 11.2:

   The 422 (Unprocessable Entity) status code means the server
   understands the content type of the request entity (hence a
   415(Unsupported Media Type) status code is inappropriate), and the
   syntax of the request entity is correct (thus a 400 (Bad Request)
   status code is inappropriate) but was unable to process the contained
   instructions.  For example, this error condition may occur if an XML
   request body contains well-formed (i.e., syntactically correct), but
   semantically erroneous, XML instructions.


=head1 AUTHOR

Fitz ELLIOTT <felliott@fiskur.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by the Rector and Visitors of the
University of Virginia.

This is free software, licensed under:

 The Artistic License 2.0 (GPL Compatible)

=cut
