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

use Excel::Writer::XLSX ();
use Spreadsheet::WriteExcel ();
use Text::CSV ();


__PACKAGE__->config(
    content_type => {
        tab => {
            mime_type     => 'text/tab-separated-values',
            extension     => 'tab',
            render_method => '_render_tab',
        },
        csv => {
            mime_type     => undef,
            extension     => 'csv',
            render_method => '_render_csv',
        },
        xls => {
            mime_type     => 'application/vnd.ms-excel',
            extension     => 'xls',
            render_method => '_render_xls',
        },
        xlsx => {
            mime_type     => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            extension     => 'xlsx',
            render_method => '_render_xlsx',
        },
    },
);


=head1 METHODS

=head2 process( $c )

Creates a tab-delimited, comma-delimited, or Excel file from tabular
data and returns it in the response body, while setting the necessary
headers.  Configuration and data are stored in the C<tabular_data>
stash key like so:

 $c->stash->{tabular_data} = {
     view => 'xls', # type of file to return, one of tab|csv|xls|xlsx
     name => 'Gene Data', # filename to save as + worksheet name for Excel
     headers => [qw/A B C/], # arrayref of column titles
     rows => [[], [], [],], # arrayref of arrayref of table data
 };

=cut

sub process {
    my ($self, $c) = @_;

    my $data_config = $c->stash->{tabular_data};
    my $view_config = $self->config->{content_type}{$data_config->{view}};

    $c->res->headers->header('Content-Type' => $view_config->{mime_type});

    my $name = $self->_normalize_name($data_config->{name});
    my $ext  = $view_config->{extension};
    $c->res->headers->header(
        'Content-Disposition' => "attachment; filename=$name.$ext"
    );

    $c->response->body(
        $self->render($c, $view_config->{render_method}, $data_config,)
    );
}


=head2 render( $c, $render_method, $data_config )

Calls the given render method.

=cut

sub render {
    my ($self, $c, $render_method, $data_config) = @_;
    return $self->$render_method($c, $data_config);
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


=head2 _render_tab

Create a tab-delimited file via Text::CSV. Forwards to
L</_render_xsv>.

=cut

sub _render_tab {
    my ($self, $c, $data_config) = @_;
    my $xsv_args = {sep_char => "\t", quote_char => undef,};
    return $self->_render_xsv($xsv_args, $data_config);
}


=head2 _render_csv

Create a comma-delimited file via Text::CSV. Forwards to
L</_render_xsv>.

=cut

sub _render_csv {
    my ($self, $c, $data_config) = @_;
    my $xsv_args = {sep_char => ',',};
    return $self->_render_xsv($xsv_args, $data_config);
}


=head2 _render_xsv

Create a delimited file via Text::CSV.

=cut

sub _render_xsv {
    my ($self, $xsv_args, $data_config) = @_;

    my $csv = Text::CSV->new({
        encoding_out => 'utf-8',
        binary       => 1,
        eol          => "\n",
        %$xsv_args,
    });

    my $output = q{};
    for my $row ($data_config->{headers}, @{ $data_config->{rows} }) {
        $csv->combine( @$row )
            or die $csv->error_diag();
        $output .= $csv->string();
    }
    return $output;
}


=head2 _render_xls

Creates an Excel 97-compatible spreadsheet. Calls L</_render_excel>.

=cut

sub _render_xls {
    my ($self, $c, $data_config) = @_;
    return $self->_render_excel('Spreadsheet::WriteExcel', $data_config);
}


=head2 _render_xlsx

Creates an Open XML Excel spreadsheet. Calls L</_render_excel>.

=cut

sub _render_xlsx {
    my ($self, $c, $data_config) = @_;
    return $self->_render_excel('Excel::Writer::XLSX', $data_config);
}


=head2 _render_excel

L<Spreadsheet::WriteExcel> and L<Excel::Writer::XLSX> use the same
interface, so this method can create spreadsheets via either module.

=cut

sub _render_excel {
    my ($self, $render_class, $data_config) = @_;

    my $output;
    open my $fh, '>', \$output;
    my $workbook = $render_class->new($fh);
    $workbook->compatibility_mode();
    my $worksheet = $workbook->add_worksheet(substr($data_config->{name}, 0, 30));
    $worksheet->write_row('A1', $data_config->{headers});
    $worksheet->write_col('A2', $data_config->{rows});
    $workbook->close();
    return $output;
}


__PACKAGE__->meta->make_immutable;
1;
__END__
