#!/usr/bin/env perl

# Author:       Fitz Elliott <felliott@virginia.edu>
# Date Created: Wed Feb 29 16:09:18 2012
# Description:  

use strict;
use warnings;
use autodie;
use feature ':5.12';

use DBIx::Class::Migration::RunScript;

main: {


    migrate {

        my $user_rs = shift
            ->schema->resultset('User');

        $user_rs->create({login => 'fge7z', name => 'Fitz Elliott'});
    };
}

