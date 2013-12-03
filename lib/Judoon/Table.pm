package Judoon::Table;

=pod

=encoding utf8

=head1 NAME

Judoon::Table - Class that represents a table of data

=head1 SYNOPSIS

 use Judoon::Table;
 my $table = Judoon::Table->new({
     data_source => $dataset,
     header_type => 'long',
     format      => 'csv',
 });

 open my $OUT, '>', 'data.csv';
 print {$OUT} $table->render;
 close $OUT;

=head1 DESCRIPTION

This module converts a source of tabular data, such as a
L<Judoon::Schema::Result::Dataset>, into a tabular data
file, such as a C<csv>, C<xls>, or C<xlsx>.

=cut


use Encode qw(encode_utf8 decode_utf8);
use Excel::Writer::XLSX ();
use Spreadsheet::WriteExcel ();
use Text::CSV ();
use Types::Standard qw(Enum ConsumerOf);

use Moo;
use namespace::clean;


=head1 ATTRIBUTES

=head2 data_source

A source of tabular data that conforms to the
L<Judoon::Schema::Role::Result::DoesTabularData> role i.e. either a
C<Result::Dataset> or C<::Result::Page>.

=head2 header_type

The type of headers to be used on the table. Must be one of C<long>,
C<short>, or C<none>. C<long> implies human-readable, C<short> implies
computer-readable, C<none> is no headers, just data

=head2 format

The format of table to produce. Must be one of: C<tsv>
(tab-separated), C<csv> (commas-separated>, C<xls> (Excel 97), or
C<xlsx> (Excel 2004).

=cut

has data_source => (
    is       => 'ro',
    isa      => ConsumerOf['Judoon::Schema::Role::Result::DoesTabularData'],
    required => 1,
    handles => {
        data          => 'data_table',
        long_headers  => 'long_headers',
        short_headers => 'short_headers',
        tabular_name  => 'tabular_name',
    },
);
has header_type => (is => 'ro', isa => Enum[qw(long short none)],  required => 1);
has format      => (is => 'ro', isa => Enum[qw(tsv csv xls xlsx)], required => 1);


=head1 METHODS

=head2 render

Render the table in the selected format.

=head2 headers

Return an ArrayRef of headers of the C<header_type>.  Returns C<undef>
if C<headers_type> is set to C<'none'>.

=head2 table

Return an ArrayRef of ArrayRefs of the data + the headers if
C<headers_type> is set to C<'long'> or C<'short'>.

=cut

sub render {
    my ($self) = @_;
    my $render_method = '_render_' . $self->format;
    return $self->$render_method();
}

sub headers {
    my ($self) = @_;
    return $self->header_type eq 'long'  ? $self->long_headers
         : $self->header_type eq 'short' ? $self->short_headers
         :                                 undef;
}

sub table {
    my ($self) = @_;
    my @data = @{$self->data};
    my $headers = $self->headers;
    unshift @data, $headers if ($headers);
    return \@data;
}


=head2 _render_tsv

Create a tab-delimited file via L</Text::CSV>.

=cut

sub _render_tsv {
    my ($self) = @_;
    my $xsv_args = {sep_char => "\t", quote_char => undef,};
    return $self->_render_xsv($xsv_args);
}


=head2 _render_csv

Create a comma-delimited file via L</Text::CSV>.

=cut

sub _render_csv {
    my ($self) = @_;
    my $xsv_args = {sep_char => ',',};
    return $self->_render_xsv($xsv_args);
}


=head2 _render_xsv

Create a delimited file via L</Text::CSV>.

=cut

sub _render_xsv {
    my ($self, $xsv_args) = @_;

    my $csv = Text::CSV->new({
        binary       => 1,
        eol          => "\n",
        %$xsv_args,
    });

    my $output = q{};
    for my $row (@{$self->table}) {
        $csv->combine( map {decode_utf8($_)} @$row )
            or die $csv->error_diag();
        $output .= encode_utf8($csv->string());
    }
    return $output;
}


=head2 _render_xls

Creates an Excel 97-compatible spreadsheet.

=cut

sub _render_xls {
    my ($self) = @_;
    return $self->_render_excel('Spreadsheet::WriteExcel');
}


=head2 _render_xlsx

Creates an Open XML Excel spreadsheet.

=cut

sub _render_xlsx {
    my ($self) = @_;
    return $self->_render_excel('Excel::Writer::XLSX');
}


=head2 _render_excel

L<Spreadsheet::WriteExcel> and L<Excel::Writer::XLSX> use the same
interface, so this method can create spreadsheets via either module.

=cut

sub _render_excel {
    my ($self, $render_class) = @_;

    my $output;
    open my $fh, '>', \$output;
    my $workbook = $render_class->new($fh);
    $workbook->compatibility_mode();
    my $name = substr($self->tabular_name, 0, 30);
    $name =~ s/[^\w ]/_/g;
    $name =~ s/__+/_/g;
    my $worksheet = $workbook->add_worksheet($name);
    $worksheet->write_col('A1', $self->table);
    $workbook->close();
    return $output;
}


1;
__END__
