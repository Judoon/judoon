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

These attributes are named for the role they play in an analogous SQL
C<SELECT> statement.  Assuming that the source dataset is called
C<this_table> and the external dataset is called C<that_table> the SQL
statement would appear like so:

 ALTER TABLE this_table ADD COLUMN new_column_name result_data_type();

 UPDATE this_table SET this_table.new_column_name=(
   SELECT that_table.that_selectcol_id
   FROM that_table
   WHERE this_table.this_joincol_id=that_table.that_joincol_id
 );


=head2 this_joincol_id

The id of the column in C<this_table> that is being joined on.

=head2 that_joincol_id

The id of the column in C<that_table> that is being joined on.

=head2 that_selectcol_id

The id of the column in C<that_table> which contains the desired data.

=cut

has this_joincol_id   => (is => 'ro', required => 1,);
has that_joincol_id   => (is => 'ro', required => 1,);
has that_selectcol_id => (is => 'ro', required => 1,);


=head1 REQUIRED METHODS

=head2 result_data_type

The L<Judoon::Type> of the product of the lookup.

=head2 lookup( \@col_data )

The subroutine that performs the transform. Takes an arrayref of data
to lookup and returns an similarly sized arrayref of the lookup data.

=head2 validate_args()

Validates that C<that_joincol_id> and C<that_selectcol_id> are valid
identifiers in C<join_dataset>.

=cut

requires 'result_data_type';
requires 'lookup';
requires 'validate_args';


=head1 METHODS

=head2 BUILD

Validate the arguments to the actor after object construction.

=cut

sub BUILD {
    my ($self) = @_;
    die 'Invalid Actor Parameters!'
        unless ( $self->validate_args() );
}

1;
__END__

=head1 AUTHOR

Fitz ELLIOTT <felliott@fiskur.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by the Rector and Visitors of the
University of Virginia.

This is free software, licensed under:

 The Artistic License 2.0 (GPL Compatible)

=cut
