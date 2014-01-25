package Judoon::API::Resource::Role::Tabular;

use Judoon::Table;

use Moo::Role;
with 'Judoon::Role::MimeTypes';

requires 'item';

my @supported = qw(tsv csv xls xlsx);

sub to_tsv  { $_[0]->_render_table('tsv'); }
sub to_csv  { $_[0]->_render_table('csv'); }
sub to_xls  { $_[0]->_render_table('xls'); }
sub to_xlsx { $_[0]->_render_table('xlsx'); }
sub _render_table {
    my ($self, $format) = @_;
    my $table = Judoon::Table->new({
        data_source => $self->item,
        header_type => 'long',
        format      => $format,
    });

    return $table->render;
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

Judoon::API::Resource::Role::Tabular - Role for Tabular Items.

=head1 METHODS

=head2 to_tsv / to_csv / to_xls / to_xlsx

Return the data in the requested file format.

=cut

=head1 AUTHOR

Fitz ELLIOTT <felliott@fiskur.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by the Rector and Visitors of the
University of Virginia.

This is free software, licensed under:

 The Artistic License 2.0 (GPL Compatible)

=cut
