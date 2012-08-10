package Judoon::Spreadsheet;

=pod

=encoding utf8

=head1 NAME

Judoon::Spreadsheet - spreadsheet parsing module

=head1 SYNOPSIS

 use Judoon::Spreadsheet;
 my $data = Judoon::Spreadsheet::read_spreadsheet($filehandle, 'xls');

=head1 DESCRIPTION

This module is currently a thin wrapper around L<Spreadsheet::Read>
that takes a filehandle and optional parser specification (i.e. file
type, 'xls', 'csv', 'xlsx') and returns a data structure representing
that spreadsheet.

=cut

use strict;
use warnings;

use Judoon::Error::Fatal;
use Method::Signatures;
use Spreadsheet::Read ();

=head1 METHODS

=head2 read_spreadsheet( $filehandle, $parser )

C<read_spreadsheet()> takes in a filehandle arg and attempts to read
it with L<Spreadsheet::Read>.  It will then munge the data and return
a data structure compatible with a C<Judoon::DB::User::Schema::Result::Dataset>
object.

=cut

sub read_spreadsheet {
    my ($fh, $parser) = @_;

    Judoon::Error::Fatal->throw({message => 'read_spreadsheet() needs a filehandle'})
          unless ($fh);
    $parser ||= 'xls';
    $parser = lc($parser);

    my $ref  = Spreadsheet::Read::ReadData($fh, parser => $parser);

    my $ds   = $ref->[1];
    my $data = pivot_data($ds->{cell}, $ds->{maxrow}, $ds->{maxcol});

    my $headers = shift @$data;
    my $dataset = {
        name => $ds->{label}, original => q{},
        data => $data, notes => q{},
        ds_columns => [],
    };

    my $sort = 1;
    for my $header (@$headers) {
        push @{$dataset->{ds_columns}}, {
            name => ($header // ''), sort => $sort++,
            accession_type => q{},   url_root => q{},
        };
    }

    return $dataset;
}


=head2 pivot_data( $data, $maxrow, $maxcol )

C<pivot_data()> takes an arrayref of arrayrefs as C<$data> and pivots
it to be row-major instead of colulmn-major.  It also removes the
empty leading entries L<Spreadsheet::Read> adds so that it is
zero-indexed instead of one-indexed.

C<$maxrow> and C<$maxcol> are the maximum number of rows and columns
respectively.  While these could be calculated dynamically,
L<Spreadsheet::Read> provides them, and requiring them simplifies the
code.

=cut

func pivot_data(ArrayRef[ArrayRef] $data, Int $maxrow, Int $maxcol) {
    for my $vars (['$maxrow',$maxrow],['$maxcol',$maxcol]) {
        my $error = q{};
        if ($vars->[1] < 1) {
            $error = "$vars->[0] must be greater than 0! got: **$vars->[1]**";
        }
        Judoon::Error::Fatal->throw({message => $error}) if ($error);
    }

    my $pivoted = [];
    for my $row_idx (0..$maxrow-1) {
        for my $col_idx (0..$maxcol-1) {
            $pivoted->[$row_idx][$col_idx] = $data->[$col_idx+1][$row_idx+1];
        }
    }

    return $pivoted;
}



1;
__END__
