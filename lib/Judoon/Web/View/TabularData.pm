package Judoon::Web::View::TabularData;

use Moose;
use namespace::autoclean;

extends 'Catalyst::View';

use Excel::Writer::XLSX ();
use Spreadsheet::WriteExcel ();
use Text::CSV::Encoded ();


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

sub process {
    my ($self, $c) = @_;
    my $content = $self->render($c);
    $c->response->body($content);
}

sub render {
    my ($self, $c) = @_;

    my $data_config = $c->stash->{tabular_data};
    my $view_config = $self->config->{content_type}{$data_config->{view}};

    # normalize name
    my $name = $data_config->{name};
    $name =~ s/\W/_/g;
    $name =~ s/__+/_/g;
    $name =~ s/(?:^_+|_+$)//g;
    my $ext = $view_config->{extension};

    $c->res->headers->header('Content-Type' => $view_config->{mime_type});
    $c->res->headers->header(
        'Content-Disposition' => "attachment; filename=$name.$ext"
    );


    my $content;
    my $render_method = $view_config->{render_method};
    return $self->$render_method($c, $data_config);
}



sub _render_tab {
    my ($self, $c, $data_config) = @_;
    my $xsv_args = {sep_char => "\t",quote_char => undef,};
    return $self->_render_xsv($xsv_args, $data_config);
}

sub _render_csv {
    my ($self, $c, $data_config) = @_;
    my $xsv_args = {sep_char => ',',};
    return $self->_render_xsv($xsv_args, $data_config);
}

sub _render_xsv {
    my ($self, $xsv_args, $data_config) = @_;

    my $csv = Text::CSV::Encoded->new({
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

sub _render_xls {
    my ($self, $c, $data_config) = @_;
    return $self->_render_excel('Spreadsheet::WriteExcel', $data_config);
}

sub _render_xlsx {
    my ($self, $c, $data_config) = @_;
    return $self->_render_excel('Excel::Writer::XLSX', $data_config);
}

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
