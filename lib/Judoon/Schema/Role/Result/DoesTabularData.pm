package Judoon::Schema::Role::Result::DoesTabularData;

use Moo::Role;

requires 'data_table';
requires 'long_headers';
requires 'short_headers';
requires 'tabular_name';


1;
__END__

=pod

=encoding utf8

=head1 NAME

Judoon::Schema::Role::Result::DoesTabularData - Interface role for tabular data sources

=head1 DESCRIPTION

This Role describes an interface for data sources that can be
represented as a table.  Currently this is used by the C<Dataset> and
C<Page> L<Judoon::Schema::Result>s.

=head1 REQUIRED METHODS

=head2 data_table

An ArrayRef of ArrayRefs of the table data in row-major order.  Column
order should match that provided by L</longe_headers()> and L</short_headers()>.

=head2 long_headers

An ArrayRef of human-readable column names.

=head2 short_headers

An ArrayRef of computer-readable column names.

=head2 tabular_name

A string that can be used to name the table.

=head1 AUTHOR

Fitz ELLIOTT <felliott@fiskur.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by the Rector and Visitors of the
University of Virginia.

This is free software, licensed under:

 The Artistic License 2.0 (GPL Compatible)

=cut
