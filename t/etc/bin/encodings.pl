#!/usr/bin/env perl

# Author:       Fitz Elliott <felliott@virginia.edu>
# Date Created: Tue Feb 12 14:27:27 2013
# Description:  generate test spreadsheets with different encodings

use utf8;
use strict;
use warnings;
use autodie;
use feature ':5.16';

use Excel::Writer::XLSX;
use IO::All;
use Spreadsheet::WriteExcel;

main: {
    my $name     = 'sheet-üñîçø∂é';
    my $data     = "ÜñîçøðÆ\nEllipsis…\n‘Single Quotes’\n“Double quotes”";
    my @data_tbl = map {[$_]} split /\n/, $data;

    my @encodings = qw(utf-8 cp1252);
    for my $enc (@encodings) {
        io("encoding-${enc}.txt")->encoding($enc)->print($data);

        my $workbook = Spreadsheet::WriteExcel->new("encoding-${enc}.xls");
        $workbook->compatibility_mode();
        $workbook->set_codepage($enc eq 'utf-8' ? 2 : 1);
        my $worksheet = $workbook->add_worksheet();
        $worksheet->write_col('A1', \@data_tbl);
        $workbook->close();

        my $workbook_x = Excel::Writer::XLSX->new("encoding-${enc}.xlsx");
        $workbook_x->compatibility_mode();
        $workbook_x->set_codepage($enc eq 'utf-8' ? 2 : 1);
        my $worksheet_x = $workbook_x->add_worksheet();
        $worksheet_x->write_col('A1', \@data_tbl);
        $workbook_x->close();
    }

    exit;
}
