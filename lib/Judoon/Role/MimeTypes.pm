package Judoon::Role::MimeTypes;

use MIME::Types;

use Moo::Role;

has _mime_types => (is => 'lazy', builder => sub { MIME::Types->new });

sub mime_type_for {
    my ($self, $ext) = @_;
    return $self->_mime_types->mimeTypeOf($ext)->type();
}


1;
__END__


=pod

=encoding utf8

=head1 NAME

Judoon::Role::MimeTypes - basic MIME::Types support

=head1 DESCRIPTION

This role holds a L</MIME::Types> decoder object and provides a
shortcut method for looking up MIME types by extension.

=head1 Attributes

=head2 _mime_types

A L</MIME::Types> object.

=head1 Methods

=head2 mime_type_for( $extension )

Returns the MIME type for a file with the given C<$extension> e.g.
C<mime_type_for('csv')> returns C<'text/comma-separated-values'>.

=cut
