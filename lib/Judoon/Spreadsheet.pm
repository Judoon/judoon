package Judoon::Spreadsheet;

=pod

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


use Moo;
use MooX::Types::MooseLike::Base qw(Str Int ArrayRef HashRef FileHandle);

use Data::Printer;
use Data::UUID;
use Excel::Reader::XLSX;
use IO::File ();
use List::Util ();
use Regexp::Common;
use Safe::Isa;
use Spreadsheet::ParseExcel;
use Text::CSV::Encoded coder_class => 'Text::CSV::Encoded::Coder::EncodeGuess';


=head1 METHODS

=head2 new / BUILD

C<Judoon::Spreadsheet> takes one of two sets of arguments to C<new()>:

 ->new({filename => 'name-of-file.xls'})
 # -or-
 ->new({filehandle => $fh, filetype => 'xls'});

The C<filename> arg will be transformed into the C<filehandle> and
C<filetype> args.  If you pass all three, the C<filename> arg will
take precedence.

The spreadsheet will be read and processed during object construction
(no laziness here!).  Don't call the C<BUILD> method, that's called
automatically by L<Moo>. I'm just mentioning it to improve my pod
coverage.

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
        die "Don't pass filename and filehandle to Judoon::Spreadsheet->new"
            if (exists $args->{filehandle});

        die "No such file $filename in constructor of Judoon::Spreadsheet"
            unless (-e $filename);

        my ($filetype) = ($filename =~ m/\.([^\.]+)$/);
        die "Couldn't determine file type of $filename"
            unless ($filetype);

        die "Invalid file format: $filetype"
            if ($filetype !~ m/^xlsx?|csv|tab/);
        $args->{filetype} = $filetype eq 'tab' ? 'csv' : $filetype;

        my $spreadsheet_fh = IO::File->new($filename, 'r')
            or die "Unable to open file $filename: $!";
        $args->{filehandle} = $spreadsheet_fh;
    }

    return $args;
};


sub BUILD {
    my ($self) = @_;

    my %parsertype_map = (
        xls  => { build => '_build_from_xls',  data_type => '_get_xls_data_type',  },
        xlsx => { build => '_build_from_xlsx', data_type => '_get_xlsx_data_type', },
        csv  => { build => '_build_from_csv',  data_type => '_get_csv_data_type',  },
    );
    my $build_meth  = $parsertype_map{ $self->filetype }->{build};
    my $type_meth   = $parsertype_map{ $self->filetype }->{data_type};
    my ($name, $data) = $self->$build_meth();

    $self->{name} = $name;
    my $headers          = shift @$data;
    $self->{data}        = $data;
    $self->{nbr_rows}    = scalar @$data;
    $self->{nbr_columns} = scalar @{ $data->[0] };

    my ($colidx, @fields, %sql_seen, %header_seen) = (1);
    for my $header (@$headers) {
        my $shortname = $self->_unique_sqlname(\%sql_seen, $header);
        $header = $self->_unique_header(\%header_seen, $header);

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
        push @fields, {
            name => $header,    shortname   => $shortname,
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

    my $parser    = Spreadsheet::ParseExcel->new;
    my $workbook  = $parser->parse($self->filehandle);
    my @allsheets = $workbook->worksheets;
    my $worksheet = $allsheets[0];
    die "Couldn't find a worksheet" unless ($worksheet);

    $self->{_parser_obj} = $worksheet;

    my ($row_min, $row_max) = $worksheet->row_range();
    my ($col_min, $col_max) = $worksheet->col_range();

    my @data;
    for my $row ( $row_min .. $row_max ) {
        my @row_data;
        for my $col ( $col_min .. $col_max ) {
            push @row_data, $worksheet->get_cell( $row, $col )
                ->$_call_if_object('value');
        }
        push @data, \@row_data;
    }

    return ($worksheet->get_name, \@data);
}

sub _get_xls_data_type {
    my ($self, $column_idx) = @_;
    return $self->_parser_obj->get_cell(2,$column_idx)
        ->$_call_if_object('type');
}


sub _build_from_csv {
    my ($self) = @_;

    my $parser = Text::CSV::Encoded->new({
        encoding_in  => ['utf-8','cp1252'],
        encoding_out => 'utf-8',
    }) or die Text::CSV::Encoded->error_diag;
    $self->{_parser_obj} = $parser;

    my $data = $parser->getline_all( $self->filehandle )
        or die Text::CSV::Encoded->error_diag;
    my $name = 'IO';
    return ($name, $data);
}

sub _get_csv_data_type { return 'text'; }


sub _build_from_xlsx {
    my ($self) = @_;

    my $parser    = Excel::Reader::XLSX->new;
    my $workbook  = $parser->read_filehandle( $self->filehandle )
        or die $parser->error();
    my @allsheets = $workbook->worksheets;
    my $worksheet = $allsheets[0];
    die "Couldn't find a worksheet" unless ($worksheet);

    $self->{_parser_obj} = $worksheet;

    my @data;
    while ( my $row = $worksheet->next_row() ) {
        my @row;
        while ( my $cell = $row->next_cell() ) {
            push @row, $cell->value();
        }
        push @data, \@row;
    }

    return ($worksheet->name, \@data);
}
sub _get_xlsx_data_type { return 'text'; }


=head2 name

The name of the spreadsheet.  For Excel spreadsheets, this is the name
of the worksheet.  For text files, it defaults to 'IO'.

=head2 fields

An arrayref of hashrefs of metadata about the columns.  Keys are:
C<name>, C<shortname>, C<type>, C<excel_type>, C<heuristic_type>.

=over

=item name

The actual text of the column, assumed to be the header value.

=item shortname

An sql-normalized version of the name, suitable for use as an SQL
column name.  Must be unique to the entire dataset, so may have
trailing integers appended.  In the pathological case where more than
100 columns have the same name, we start appending UUIDs. Don't do that.

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
heurisitic data types are: 'integer', 'numeric', and 'text'.

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


# generate a unique sql-valid name for a column based off its text
# name.
sub _unique_sqlname {
    my ($self, $seen, $name) = @_;

    # stolen from SQL::Translator::Utils::normalize_name
    # The name can only begin with a-zA-Z_; if there's anything
    # else, prefix with _
    $name =~ s/^([^a-zA-Z_])/_$1/;

    # anything other than a-zA-Z0-9_ in the non-first position
    # needs to be turned into _
    $name =~ tr/[a-zA-Z0-9_]/_/c;

    # All duplicated _ need to be squashed into one.
    $name =~ tr/_/_/s;

    # Trim a trailing _
    $name =~ s/_$//;

    $name = lc $name;

    return $name if (!$seen->{$name}++);

    for my $suffix (map {sprintf '%02d', $_} 1..99) {
        my $new_colname = $name . '_' . $suffix;
        return $new_colname if (!$seen->{$new_colname}++);
    }

    for my $i (0..10) {
        my $uuid = Data::UUID->new->create_str();
        my $uuid_name = $name . '_' . $uuid;
        return $uuid_name if(!$seen->{$uuid_name}++);
    }

    die "absolutely insane. How can we not generate a unique name for this?"
        . p(%{ {name => $name, seen => $seen} });
}


# generate a unique column title
sub _unique_header {
    my ($self, $seen, $header) = @_;

    return $header if (not $seen->{$header}++);

    for my $i (1..999) {
        my $new_header = $header . " ($i)";
        return $new_header if (not $seen->{$new_header}++);
    }

    for my $i (0..10) {
        my $uuid = Data::UUID->new->create_str();
        my $uuid_name = $header . " ($uuid)";
        return $uuid_name if(not $seen->{$uuid_name}++);
    }

    die "absolutely insane. How can we not generate a unique name for this?"
        . p(%{ {header => $header, seen => $seen} });
}


1;
__END__
