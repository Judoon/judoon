package Judoon::Search::Document::Role::Permission;

use Moose::Role;

use MooseX::Types::Moose qw(Bool);

has private => (
    traits  => ['ElasticField'],
    is      => 'ro',
    isa     => Bool,
    default => 1,
);

1;
__END__
