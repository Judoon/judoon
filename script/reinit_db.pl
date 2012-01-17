#!/usr/bin/env perl

# Author:       Fitz Elliott <felliott@virginia.edu>
# Date Created: Mon Jan 16 14:30:35 2012
# Description:  

use strict;
use warnings;
use autodie;
use feature ':5.12';

use FindBin '$Bin';
use lib "$Bin/../lib";

use Judoon::DB::Users;

main: {
    my $j = Judoon::DB::Users->new;
    $j->reinit;
}
