package Judoon::Web::View::TabularData;

=pod

=encoding utf8

=head1 NAME

Judoon::Web::View::TabularData - Serving tabular data from Judoon::Web

=head1 DESCRIPTION

Serve up tabular data as downloads in csv, tab, and Excel formats

=cut

use Moose;
use namespace::autoclean;

extends 'Catalyst::View';

use MIME::Types;

has mime_types => (is => 'ro', lazy => 1, builder => '_build_mime_types');
sub _build_mime_types { return MIME::Types->new; }


=head1 METHODS

=head2 process( $c )

Creates a tab-delimited, comma-delimited, or Excel file from a
L<Judoon::Table> object and returns it in the response body, while
setting the necessary headers.  The L<Judoon::Table> object should be
stored in the C<tabular_data> stash key;

=cut

sub process {
    my ($self, $c) = @_;

    my $table = $c->stash->{tabular_data};
    my $ext   = $table->format;
    $c->res->headers->header('Content-Type' => $self->_mime_type_for($ext));

    my $name = $self->_normalize_name($table->tabular_name);
    $c->res->headers->header(
        'Content-Disposition' => "attachment; filename=$name.$ext"
    );
    $c->response->body($table->render);
}


=head2 _normalize_name( $name )

Simplify download file name by replacing non-words chars with
underscores, then removing extraneous underscores.  If the new name is
empty, instead return 'untitled'.

=cut

sub _normalize_name {
    my ($self, $name) = @_;
    $name =~ s/\W/_/g;
    $name =~ s/__+/_/g;
    $name =~ s/(?:^_+|_+$)//g;
    return $name || 'untitled';
}


sub _mime_type_for {
    my ($self, $ext);
    return $self->mime_types->mimeTypeOf($_)->type();
}

__PACKAGE__->meta->make_immutable;
1;
__END__
