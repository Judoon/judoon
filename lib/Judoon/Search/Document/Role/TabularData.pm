package Judoon::Search::Document::Role::TabularData;

use Moose::Role;

use MooseX::Types::Common::Numeric qw(PositiveInt);
use MooseX::Types::DateTime qw(DateTime);
use MooseX::Types::Moose qw(Str ArrayRef);

has owner => (
    traits => ['ElasticField'],
    is     => 'ro',
    isa    => Str
);

has headers => (
    traits => ['ElasticField'],
    is     => 'ro',
    isa    => ArrayRef[Str],
);
has data => (
    traits => ['ElasticField'],
    is     => 'ro',
    isa    => ArrayRef[ArrayRef],
);

has nbr_rows => (
    traits => ['ElasticField'],
    is     => 'ro',
    isa    => PositiveInt,
);
has nbr_columns => (
    traits => ['ElasticField'],
    is     => 'ro',
    isa    => PositiveInt,
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
