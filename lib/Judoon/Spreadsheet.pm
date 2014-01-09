package Judoon::Spreadsheet;

=pod

=for stopwords filetype shortname

=encoding utf8

=head1 NAME

Judoon::Spreadsheet - spreadsheet parsing module

=head1 SYNOPSIS

 use Judoon::Spreadsheet;
 my $js = Judoon::Spreadsheet->new({filename => $fn});
 say $js->name;  # worksheet name
 say Dumper($js->data); # [ [], [], [], [], ] row-major

=head1 DESCRIPTION

This module is an abstraction around different kinds of
spreadsheets. It can parse Excel '97, Excel XML, and CSV files.
It takes either a filename or a filehandle and file type
(e.g. 'xls', 'csv', 'xlsx') and returns a object with methods for
getting at the name, columns, and data of that spreadsheet.

=cut


use Encode qw(decode);
use Encode::Guess;
use IO::File ();
use Judoon::Error::Devel::Arguments;
use Judoon::Error::Devel::Foreign;
use Judoon::Error::Input::File;
use Judoon::Error::Input::Filename;
use Judoon::Error::Spreadsheet;
use Judoon::Error::Spreadsheet::Encoding;
use Judoon::Error::Spreadsheet::Type;
use List::Util ();
use MooX::Types::MooseLike::Base qw(Str Int ArrayRef HashRef FileHandle);
use Regexp::Common;
use Safe::Isa;
use Spreadsheet::ParseExcel;
use Spreadsheet::ParseXLSX;
use Text::CSV;

use Moo;
use namespace::clean;


=head1 METHODS

=for Pod::Coverage BUILDARGS BUILD

=head2 new

C<Judoon::Spreadsheet> takes one of two sets of arguments to C<new()>:

 ->new({filename => 'name-of-file.xls'})
 # -or-
 ->new({filehandle => $fh, filetype => 'xls'});

The C<filename> argument will be transformed into the C<filehandle>
and C<filetype> arguments.  If you pass all three, the C<filename>
argument will take precedence.

The spreadsheet will be read and processed during object construction
(no laziness here!).

=head2 filehandle

The filehandle passed to the constructor.  If the underlying file is
an B<xlsx> file, the filehandle must be seekable, so use L<IO::File>.

 my $xlsx_fh = IO::File->new('sheet.xlsx', 'r');

=head2 filetype

The type of file being passed in.  One of C<xls>, C<xlsx>, or C<csv>.

=cut

has filehandle => (is => 'ro', isa => FileHandle, required => 1,);
has filetype   => (is => 'ro', isa => Str, required => 1,);

around BUILDARGS => sub {
    my ($orig, $class, @args) = @_;

    my $args = $class->$orig(@args);

    if (my $filename = delete $args->{filename}) {
        Judoon::Error::Devel::Arguments->throw({
            message  => "Don't pass filename and filehandle to Judoon::Spreadsheet->new",
            got      => $args->{flehandle},
            expected => 'undef',
        }) if (exists $args->{filehandle});

        Judoon::Error::Input::Filename->throw({
            message  => "No such file $filename",
            filename => $filename,
        }) unless (-e $filename);

        my ($filetype) = ($filename =~ m/\.([^\.]+)$/);
        Judoon::Error::Input::Filename->throw({
            message => "Couldn't determine file type of $filename from extension (extension seems to be missing?)",
            filename => $filename,
        }) unless ($filetype);
        $args->{filetype} = $filetype;

        my $spreadsheet_fh = IO::File->new($filename, 'r')
            or Judoon::Error::Input::File->throw({
                message => "Unable to open file $filename: $!",
            });
        $args->{filehandle} = $spreadsheet_fh;
    }

    return $args;
};


sub BUILD {
    my ($self) = @_;

    Judoon::Error::Spreadsheet::Type->throw({
        message => 'Invalid file format: ".' . $self->filetype . '".'
            . ' Must be one of: ".csv",".xls",".xlsx"',
    }) if ($self->filetype !~ m/^(?:xlsx?|[ct]sv)$/);

    my %parsertype_map = (
        xls  => { build => '_build_from_xls',  data_type => '_get_excel_data_type', },
        xlsx => { build => '_build_from_xlsx', data_type => '_get_excel_data_type', },
        csv  => { build => '_build_from_csv',  data_type => '_get_xsv_data_type',   },
        tsv  => { build => '_build_from_tsv',  data_type => '_get_xsv_data_type',   },
    );
    my $build_meth  = $parsertype_map{ $self->filetype }->{build};
    my $type_meth   = $parsertype_map{ $self->filetype }->{data_type};
    my ($name, $data) = $self->$build_meth();
    $self->filehandle->close();

    $self->{name} = $name;
    my $headers          = shift @$data;
    $self->{data}        = $data;
    $self->{nbr_rows}    = scalar @$data;
    $self->{nbr_columns} = scalar @{ $data->[0] };

    my ($colidx, @fields) = (1);
    for my $header (@$headers) {
        my $parser_type = $self->$type_meth( $colidx );
        my %heuristic_types;
        for my $row (@$data) {
            my $datum = $row->[ $colidx-1 ];
            next if !defined $datum || $datum eq '';
            my $type = $datum =~ m/^$RE{num}{int}$/  ? 'integer'
                     : $datum =~ m/^$RE{num}{real}$/ ? 'numeric'
                     :                                'text';
            $heuristic_types{ $type }++;
        }
        my $heuristic_type = List::Util::first {$heuristic_types{$_}}
            qw(text numeric integer);
        $heuristic_type //= 'text';

        my $data_type = $heuristic_type eq 'integer' ? 'numeric'
                      :                                $heuristic_type;
        $header //= q{};
        push @fields, {
            name => $header,
            type => $data_type, parser_type => $parser_type,
            heuristic_type => $heuristic_type,
        };
        $colidx++;
    }
    $self->{fields} = \@fields;
}


has _parser_obj => (is => 'ro', init_arg => undef,);

sub _build_from_xls {
    my ($self) = @_;
    my $parser = Spreadsheet::ParseExcel->new;
    return $self->_parse_excel($parser);
}

sub _build_from_xlsx {
    my ($self) = @_;
    my $parser = Spreadsheet::ParseXLSX->new;
    return $self->_parse_excel($parser);
}

sub _parse_excel {
    my ($self, $parser) = @_;

    my $workbook  = $parser->parse($self->filehandle);
    my @allsheets = $workbook->worksheets;
    my $worksheet = $allsheets[0];
    Judoon::Error::Spreadsheet->throw({
        message  => "Couldn't find a worksheet",
        filetype => $self->filetype,
    }) unless ($worksheet);

    $self->{_parser_obj} = $worksheet;

    my ($row_min, $row_max) = $worksheet->row_range();
    my ($col_min, $col_max) = $worksheet->col_range();

    my @data;
    for my $row ( $row_min .. $row_max ) {
        my @row_data;
        for my $col ( $col_min .. $col_max ) {
            my $cell = $worksheet->get_cell($row, $col);
            my $val  = $cell->$_call_if_object('value');

            # Weirdness ensues...
            if ($cell) {
                # Spreadsheet::ParseExcel is not consistent about how
                # it returns values.  If a cell contains a string with
                # with unicode codepoints that requires more than one
                # byte (e.g. 'Ellipsis…', where the character
                # HORIZONTAL ELLIPSIS is codepoint 0x2026), it decodes
                # the cell into a proper perl string. However, if the
                # string contains only characters representable in
                # single-byte unicode codepoints (e.g. 'ÜñîçøðÆ'), it
                # does not get decoded. utf8::upgrade() will decode it
                # if it is not yet decoded, and leave it alone
                # otherwise.

                # Spreadsheet::ParseExcel claims to support other
                # encoding types, but I don't have examples of these,
                # so I can't test them yet.  Until then, die when we
                # encounter them.
                my $enc = $cell->encoding();
                ($enc == 1 || $enc == 2)
                    ? utf8::upgrade($val)
                    : Judoon::Error::Spreadsheet::Encoding->throw({
                        message  => 'Unhandled cell encoding type in XLS parser',
                        encoding => ($enc == 3 ? 'UTF16-BE'
                                  :  $enc == 4 ? 'pre-Excel 97 encoding'
                                  :              "unknown type: $enc"),
                        filetype => $self->filetype,
                    });
            }

            push @row_data, ($val // '');

        }
        push @data, \@row_data;
    }


    # How come? see the above note for cell data. worksheet name
    # suffers the same problem.
    my $name = $worksheet->get_name;
    utf8::upgrade($name);
    return ($name, \@data);
}

sub _get_excel_data_type {
    my ($self, $column_idx) = @_;
    return $self->_parser_obj->get_cell(2,$column_idx)
        ->$_call_if_object('type');
}



sub _build_from_csv {
    my ($self) = @_;

    my $parser = Text::CSV->new({binary => 1})
        or Judoon::Error::Devel::Foreign->throw({
            message => q{Couldn't create CSV decoder object'},
            module  => 'Text::CSV',
            foreign_message => Text::CSV->error_diag,
        });
    return $self->_build_from_xsv($parser);
}

sub _build_from_tsv {
    my ($self) = @_;

    my $parser = Text::CSV->new({binary => 1, sep_char => "\t"})
        or Judoon::Error::Devel::Foreign->throw({
            message => q{Couldn't create CSV decoder object'},
            module  => 'Text::CSV',
            foreign_message => Text::CSV->error_diag,
        });
    return $self->_build_from_xsv($parser);
}


sub _build_from_xsv {
    my ($self, $parser) = @_;

    $self->{_parser_obj} = $parser;

    my @data;
    while (my $row = $parser->getline( $self->filehandle )) {
        my @decoded;
        for my $cell (@$row) {
            if (!defined($cell) || ($cell eq '')) {
                push @decoded, $cell;
            }
            else {
                my $enc = guess_encoding($cell, qw(utf-8 cp1252));
                ref($enc) or die qq{Can't guess encoding for: $cell};
                push @decoded,
                    $enc->name eq 'utf8' ? $cell : $enc->decode($cell);
            }
        }
        push @data, \@decoded;
    }

    my $name = 'IO';
    return ($name, \@data);
}

sub _get_xsv_data_type { return 'text'; }


=head2 name

The name of the spreadsheet.  For Excel spreadsheets, this is the name
of the worksheet.  For text files, it defaults to 'IO'.

=head2 fields

An arrayref of hashrefs of metadata about the columns.  Keys are:
C<name>, C<type>, C<excel_type>, C<heuristic_type>.

=over

=item name

The actual text of the column, assumed to be the header value.

=item type / excel_type / heuristic_type

The data type of the column. C<type> is intended to be canonical and
is currently set to whatever the C<heuristic_type> is, though a
C<heuristic_type> of 'integer' is downgraded to 'numeric'.

C<excel_type> is the type as reported by the Excel processing modules,
and should be equivalent to excels data types. It's saved for possible
future use.

C<heuristic_type> is calculated by scanning all of the data in a
column and matching against successively more liberal regexes to
figure out what type of data it is. A tally is kept, and the most
liberal type wins.  i.e. if a column has ten data that are integers,
and one that is text, the column will be marked as 'text'.  Current
heuristic data types are: 'integer', 'numeric', and 'text'.

=back

=head2 data

An arrayref of arrayrefs containing the actual data of the
spreadsheet.  Row-major, so data->[0] represents row 1, data->[0][0]
represents row 1, column 1.  This is data only, no headers. See the
C<fields> attribute for that.

=head2 nbr_rows

The number of rows in the spreadsheet.

=head2 nbr_columns

The number of columns in the spreadsheet.

=cut

has name        => (is => 'ro', init_arg => undef, isa => Str, );
has fields      => (is => 'ro', init_arg => undef, isa => ArrayRef[HashRef],);
has data        => (is => 'ro', init_arg => undef, isa => ArrayRef[ArrayRef],);
has nbr_rows    => (is => 'ro', init_arg => undef, isa => Int, );
has nbr_columns => (is => 'ro', init_arg => undef, isa => Int, );



1;
__END__
