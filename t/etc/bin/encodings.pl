#!/usr/bin/env perl

# Author:       Fitz Elliott <felliott@virginia.edu>
# Date Created: Tue Feb 12 14:27:27 2013
# Description:  generate test spreadsheets with different encodings

use utf8;
use strict;
use warnings;
use autodie;
use feature ':5.16';

use IO::All;

main: {
    my $name = 'sheet-üñîçø∂é';
    my $data = "ÜñîçøðÆ\nEllipsis…\n‘Single Quotes’\n“Double quotes”";

    my @encodings = qw(utf-8 cp1252);
    for my $enc (@encodings) {
        io("encoding-${enc}.txt")->encoding($enc)->print($data);
    }

    exit;
}
