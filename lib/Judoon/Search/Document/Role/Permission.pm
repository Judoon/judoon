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


=pod

=encoding utf8

=head1 NAME

Judoon::Search::Document::Role::Permission - Is this Document public?

=head1 DESCRIPTION

A Document that consumes this role can indicate whether it is a public
or private resource.

=head1 ATTRIBUTES

=head2 private

Boolean.  True if this document is private and should not be search by
default.

=cut
