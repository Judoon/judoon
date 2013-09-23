package Judoon::Lookup::Role::Base;

use Types::Standard qw(Str);

use Moo::Role;

has schema     => (is => 'ro', required => 1,);
has that_table => (is => 'ro', required => 1,);
has dataset    => (is => 'ro', required => 1,);


requires 'id';
requires 'name';

has group_id    => (is => 'ro', isa => Str, required => 1,);
has group_label => (is => 'ro', isa => Str, required => 1,);

requires 'input_columns';
requires 'output_columns';

requires 'input_columns_for';
requires 'output_columns_for';


sub TO_JSON {
    my ($self) = @_;

    # Examples:
    # Key         | External          | Internal
    # ------------+------------------+-------------
    # id          | uniprot           | 238
    # name        | Uniprot           | Simpson 2008
    # group_id    | external          | internal
    # group_label | External Database | My Datasets
    # full_id     | external_uniprot  | internal_238

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

=pod

=encoding utf8

=head1 NAME

Judoon::Lookup::Role::Base - Common code for Judoon::Lookups

=head1 SYNOPSIS

 package Judoon::Lookup::TimesTwo;

 use Moo;
 with 'Judoon::Lookup::Role::Base;

 sub result_data_type { CoreType_Numeric }
 sub apply_batch {
   my ($self, $data) = @_;
   return map {$_ * 2} @$data;
 }

=head1 DESCRIPTION

This is our base role for C<Judoon::Lookup>s. All C<Lookups>
should consume this role.

=head1 REQUIRED METHODS

=head2 result_data_type

The L<Judoon::Type> of the product of the transform.

=head2 apply_batch

The subroutine that performs the transform.

=cut
