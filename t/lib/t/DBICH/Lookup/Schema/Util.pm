package t::DBICH::Lookup::Schema::Util;

use strict;
use warnings;

use DBIx::Class::Candy::Exports;


# copied and pasted from someone on #dbix-class

sub integer        { 'integer' }
sub text           { 'text' }
sub serial_integer { +{ is_auto_increment => 1, data_type => integer } }

sub integer_column {
    shift->add_column( shift() => { data_type => integer } )
}

sub text_column {
    shift->add_column( shift() => +{ data_type => text } );
}

sub foreign_key_column {
    shift->add_column( shift() => +{
        data_type      => integer,
        is_foreign_key => 1,
        is_nullable    => 1,
    } );
}

export_methods([qw(
    integer_column text_column foreign_key_column
    integer text serial_integer
)]);


1;
