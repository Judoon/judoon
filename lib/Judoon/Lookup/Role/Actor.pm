package Judoon::Lookup::Role::Actor;

=pod

=for stopwords

=encoding utf8

=head1 NAME

Judoon::Lookup::Role::Actor - Common code for Judoon::Lookup::*Actors

=head1 DESCRIPTION

This is our base role for C<Judoon::Lookup::*Actor>s. All C<Lookups> should
consume this role.

=cut

use Moo::Role;


=head1 REQUIRED ATTRIBUTES

=head2 schema

An instance of L<Judoon::Schema>

=head2 this_table_id

The id of the table to which the new column is being added.

=head2 that_table_id

The id of the table from which the new data is being fetched.

=head2 this_joincol_id

The id of the column in C<this_table> that is being joined on.

=head2 that_joincol_id

The id of the column in C<that_table> that is being joined on.

=head2 that_selectcol_id

The id of the column in C<that_table> which contains the deisred data.

=cut

has schema            => (is => 'ro', required => 1,);
has this_table_id     => (is => 'ro', required => 1,);
has that_table_id     => (is => 'ro', required => 1,);
has this_joincol_id   => (is => 'ro', required => 1,);
has that_joincol_id   => (is => 'ro', required => 1,);
has that_selectcol_id => (is => 'ro', required => 1,);


=head1 REQUIRED METHODS

=head2 result_data_type

The L<Judoon::Type> of the product of the lookup.

=head2 lookup( \@col_data )

The subroutine that performs the transform. Takes an arrayref of data
to lookup and returns an similarly sized arrayref of the lookup data.

=cut

requires 'result_data_type';
requires 'lookup';


1;
__END__
