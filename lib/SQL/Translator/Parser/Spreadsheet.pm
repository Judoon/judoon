package SQL::Translator::Parser::Spreadsheet;

=head1 NAME

SQL::Translator::Parser::Spreadsheet - parser for spreadsheets

=head1 SYNOPSIS

  use SQL::Translator;

  my $translator = SQL::Translator->new;
  $translator->parser('Spreadsheet');

=head1 DESCRIPTION

Parses a spreadsheet file using Spreadsheet::Read.

=head1 OPTIONS

=over

=item * scan_fields

Indicates that the columns should be scanned to determine data types
and field sizes.  True by default.

=back

=cut

use strict;
use warnings;
our ($DEBUG, @EXPORT_OK);
$DEBUG = 0 unless defined $DEBUG;
our $VERSION = '1.59';

use Data::UUID;
use Spreadsheet::Read qw(ReadData);
use Exporter;
use SQL::Translator::Utils qw(debug normalize_name);

use base qw(Exporter);

@EXPORT_OK = qw(parse);

my %ET_to_ST  = (
    lc('Text')    => 'TEXT',
    lc('Date')    => 'DATETIME',
    lc('Numeric') => 'DOUBLE',
);

# -------------------------------------------------------------------
# parse($tr, $data)
#
# Note that $data, in the case of this parser, is unuseful.
# Spreadsheet::ParseExcel works on files, not data streams.
# -------------------------------------------------------------------
sub parse {
    my ($tr, $data) = @_;

    my $args = $tr->parser_args;

    my $wb;
    if ($args->{spreadsheet_ref}) {
        $wb = $args->{spreadsheet_ref};
    }
    else {
        my $filename = $tr->filename || return;
        $wb          = ReadData( $filename, cells => 0, attr => 1 );
    }

    my $schema      = $tr->schema;
    my $table_no    = 0;

    my $wb_count = $wb->[0]->{'sheets'} || 0;
    for my $num ( 1 .. $wb_count ) {
        last unless (exists $wb->[$num]);
        $table_no++;
        my $ws         = $wb->[$num];
        my $table_name = normalize_name( $ws->{'label'} || "Table$table_no" );

        my @cols = (1, $ws->{'maxcol'});
        next unless $cols[1] > 0;

        my $table = $schema->add_table( name => $table_name );

        my @field_names = ();
        my %colnames_seen;
        for my $col ( $cols[0] .. $cols[1] ) {
            my $cell      = $ws->{cell}[$col][1];
            my $col_name  = _unique_sqlname(\%colnames_seen, normalize_name( $cell ));
            push @field_names, $col_name;
            next unless ($col_name);

            my $data_type = @{$ws->{attr}}
                ? ET_to_ST( $ws->{attr}[$col][2]{type} )
                : 'TEXT';
            my $field = $table->add_field(
                name              => $col_name,
                data_type         => $data_type,
                is_nullable       => 1,
                is_auto_increment => undef,
            ) or die $table->error;
        }


        # If directed, look at every field's values to guess size and type.
        unless (
            defined $args->{'scan_fields'} &&
            $args->{'scan_fields'} == 0
        ) {
            my %field_info = map { $_, {} } @field_names;

            for(
                my $iR = 2;
                defined $ws->{'maxrow'} && $iR <= $ws->{'maxrow'};
                $iR++
            ) {
               for (
                    my $iC = 1;
                    defined $ws->{'maxcol'} && $iC <= $ws->{'maxcol'};
                    $iC++
                ) {
                    my $field = $field_names[ $iC-1 ];
                    my $data  = $ws->{cell}[ $iC ][ $iR ];
                    next if !defined $data || $data eq '';
                    my $type;

                    if ( $data =~ /^-?\d+$/ ) {
                        $type = 'integer';
                    }
                    elsif (
                        $data =~ /^-?[,\d]+\.[\d+]?$/
                        ||
                        $data =~ /^-?[,\d]+?\.\d+$/
                        ||
                        $data =~ /^-?\.\d+$/
                    ) {
                        $type = 'float';
                    }
                    else {
                        $type = 'text';
                    }

                    $field_info{ $field }{ $type }++;
                }
            }

            for my $field ( keys %field_info ) {
                my $data_type =
                    $field_info{ $field }{'text'}    ? 'text'    :
                    $field_info{ $field }{'float'}   ? 'double'  :
                    $field_info{ $field }{'integer'} ? 'integer' : 'text';
                my $field = $table->get_field( $field );
                $field->data_type( $data_type );
            }
        }

        last; # only import first workbook
    }

    return 1;
}

sub ET_to_ST {
    my $et = shift;
    $ET_to_ST{lc($et)} || $ET_to_ST{lc('Text')};
}


# make sure that fields in a table don't have duplicate names
sub _unique_sqlname {
    my ($seen, $colname) = @_;
    return $colname if (!$seen->{$colname}++);

    for my $suffix (map {sprintf '%02d', $_} 1..99) {
        my $new_colname = $colname . '_' . $suffix;
        return $new_colname if (!$seen->{$new_colname}++);
    }

    for my $i (0..10) {
        my $uuid = Data::UUID->new->create_str();
        my $uuid_name = $colname . '_' . $uuid;
        return $uuid_name if(!$seen->{$uuid_name}++);
    }

    die "absolutely insane.  how can we not generate a unique name for this?";
}


1;

# -------------------------------------------------------------------
# Education is an admirable thing,
# but it is as well to remember that
# nothing that is worth knowing can be taught.
# Oscar Wilde
# -------------------------------------------------------------------

=pod

=head1 AUTHORS

Mike Mellilo <mmelillo@users.sourceforge.net>,
darren chamberlain E<lt>dlc@users.sourceforge.netE<gt>,
Ken Y. Clark E<lt>kclark@cpan.orgE<gt>.

=head1 SEE ALSO

Spreadsheet::ParseExcel, SQL::Translator.

=cut
