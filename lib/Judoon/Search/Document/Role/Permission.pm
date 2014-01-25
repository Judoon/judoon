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

=head1 AUTHOR

Fitz ELLIOTT <felliott@fiskur.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by the Rector and Visitors of the
University of Virginia.

This is free software, licensed under:

 The Artistic License 2.0 (GPL Compatible)

=cut
