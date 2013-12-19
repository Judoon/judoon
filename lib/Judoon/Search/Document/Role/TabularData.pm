package Judoon::Search::Document::Role::TabularData;

use Moose::Role;

use MooseX::Types::Common::Numeric qw(PositiveOrZeroInt);
use MooseX::Types::DateTime qw(DateTime);
use MooseX::Types::Moose qw(Str ArrayRef);

has owner => (
    traits        => ['ElasticField'],
    is            => 'ro',
    isa           => 'Judoon::Search::Document::User',
    include_attrs => [qw(username name email_address)],
);

has headers => (
    traits => ['ElasticField'],
    is     => 'ro',
    isa    => Str,
    index  => 'analyzed',
);
has data => (
    traits => ['ElasticField'],
    is     => 'ro',
    isa    => Str,
    index  => 'analyzed',
);

has nbr_rows => (
    traits => ['ElasticField'],
    is     => 'ro',
    isa    => PositiveOrZeroInt,
);
has nbr_columns => (
    traits => ['ElasticField'],
    is     => 'ro',
    isa    => PositiveOrZeroInt,
);

has created => (
    traits   => ['ElasticField'],
    is       => 'ro',
    isa      => DateTime,
    required => 1,
);
has updated => (
    traits   => ['ElasticField'],
    is       => 'ro',
    isa      => DateTime,
    required => 1,
);


1;
__END__

=pod

=encoding utf8

=head1 NAME

Judoon::Search::Document::Role::TabularData - Properties of a data table

=head1 DESCRIPTION

A Document that consumes this role is claiming that it has associated
tabular data.  The Document must provide values for the following
attributes:

=head1 ATTRIBUTES

=head2 owner

The L<Judoon::Search::Document::User> who owns this Document.

=head2 headers

A string containing all the column headers for the table. This field
will be analyzed for full-text search purposes.

=head2 data

A string containing all the data for the table. This field
will be analyzed for full-text search purposes.

=head2 nbr_rows

The number of rows in the table.

=head2 nbr_columns

The number of columns in the table.

=head2 created

The date this Document was created.

=head2 updated

The date this Document was last modified.

=cut
