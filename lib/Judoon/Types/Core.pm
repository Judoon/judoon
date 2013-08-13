package Judoon::Types::Core;

use strict;
use warnings;

use Type::Library
    -base,
    -declare => qw(
        CoreType_Text
        CoreType_Numeric
        CoreType_Datetime
    );

use Judoon::Type;
use Types::Standard -types;
use Type::Tiny::Class;


__PACKAGE__->meta->add_type(
    Judoon::Type->new(
        name    => 'CoreType_Text',
        parent  => Str,
        sample  => 'some example text',
        label   => 'Text',
        pg_type => 'text',
    )
);
__PACKAGE__->meta->add_type(
    Judoon::Type->new(
        name    => 'CoreType_Numeric',
        parent  => Num,
        sample  => 1234,
        label   => 'Numeric',
        pg_type => 'numeric',
    )
);
__PACKAGE__->meta->add_type(
    Type::Tiny::Class->new(
        name  => 'CoreType_Datetime',
        class => 'DateTime',
    )
);


1;
__END__

=pod

=for stopwords DateTime

=encoding utf8

=head1 NAME

Judoon::Types::Core - Basic Judoon::Types

=head1 SYNOPSIS

 use Judoon::Types::Core qw(:all);

 CoreType_Text->check("moo");    # ok
 CoreType_Numeric->check("moo"); # not ok

=head1 DESCRIPTION

Most generic data types for Dataset Columns.

=head1 Types

=head2 CoreType_Text

Basic text.

=head2 CoreType_Numeric

Basic Numeric data.

=head2 Coretype_Datetime

A DateTime object.

=cut
