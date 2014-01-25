package Judoon::API::Resource::Role::Application;

use FileHandle;
use Judoon::Standalone;

use Moo::Role;
with 'Judoon::Role::MimeTypes';

requires 'item';

my @supported = qw(zip tgz);

sub to_zip  { $_[0]->_render_app('zip'); }
sub to_tgz  { $_[0]->_render_app('tgz'); }
sub _render_app {
    my ($self, $format) = @_;
    my $standalone   = Judoon::Standalone->new({page => $self->item});
    my $archive_path = $standalone->compress($format);
    my $archive_fh   = FileHandle->new;
    $archive_fh->open($archive_path, 'r');
    return $archive_fh;
}

around content_types_provided => sub {
    my $orig = shift;
    my $self = shift;

    return [
        @{ $orig->($self, @_) },

        map {{$self->mime_type_for($_) => "to_$_"}}
            @supported
    ];
};

1;
__END__

=pod

=encoding utf8

=head1 NAME

Judoon::API::Resource::Role::Application - Role for Application Items.

=head1 METHODS

=head2 to_zip / to_tgz

Return the application in the requested file format.

=head1 AUTHOR

Fitz ELLIOTT <felliott@fiskur.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by the Rector and Visitors of the
University of Virginia.

This is free software, licensed under:

 The Artistic License 2.0 (GPL Compatible)

=cut
