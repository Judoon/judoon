package Judoon::Lookup::Role::Base;

=pod

=for stopwords

=encoding utf8

=head1 NAME

Judoon::Lookup::Role::Base - Common code for Judoon::Lookups

=head1 DESCRIPTION

This is our base role for C<Judoon::Lookup>s. All C<Lookups> should
consume this role.  C<Lookups> provide meta-information about their
inputs and outputs and can construct Actor objects that will perform
the actual lookup.

=cut

use MooX::Types::MooseLike::Base qw(Str InstanceOf);

use Moo::Role;


=head1 REQUIRED ATTRIBUTES

=head2 user

An instance of L<Judoon::Schema::Result::User>.

=head2 dataset

A structure or reference that represents the dataset.

=head2 group_id

A normalized string representing the Lookup's group.

=head2 group_label

A freely formatted string representing the Lookup group name.

=cut

has user => (
    is       => 'ro',
    isa      => InstanceOf['Judoon::Schema::Result::User'],
    required => 1,
);
has dataset     => (is => 'ro', required => 1,);
has group_id    => (is => 'ro', isa => Str, required => 1,);
has group_label => (is => 'ro', isa => Str, required => 1,);


=head1 REQUIRED METHODS

=head2 id

An identifier for the dataset.

=head2 name

A human-readable name for the dataset.

=head2 input_columns

A list of columns that can be used to look up data.

=head2 output_columns

A list of columns that can be used to provide the returned data.

=head2 input_columns_for( $output_col_id )

Returns a list of input columns that can be used to lookup the output
column identified by C<$output_col_id>.

=head2 output_columns_for( $input_col_id )

Returns a list of output columns that can be produced when the column
identified by C<$input_col_id> is used in the join condition.

=head2 build_actor( \%attrs )

Construct and return a C<Judoon::Lookup::*Actor> of the same type as
the lookup, with the relavant Action roles added.  C<InternalActor>s
do not need any additional roles, but C<ExternalActor>s will need a
C<Judoon::Lookup::Role::Action::*> role applied to them that specifies
how extactly to lookup the given data.

=cut

requires 'id';
requires 'name';

requires 'input_columns';
requires 'output_columns';

requires 'input_columns_for';
requires 'output_columns_for';

requires 'build_actor';


=head1 PROVIDED METHODS

=head2 TO_JSON

A serializable represention of the C<Lookup>.

 Examples:
 Key         | External          | Internal
 ------------+-------------------+-------------
 id          | uniprot           | 238
 name        | Uniprot           | Simpson 2008
 group_id    | external          | internal
 group_label | External Database | My Datasets
 full_id     | external_uniprot  | internal_238

=cut

sub TO_JSON {
    my ($self) = @_;

    return {
        id          => $self->id,
        name        => $self->name,
        group_id    => $self->group_id,
        group_label => $self->group_label,
        full_id     => $self->group_id . '_' . $self->id,
    };
}


1;
__END__
