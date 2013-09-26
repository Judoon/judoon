package Judoon::Lookup::Internal;

=pod

=for stopwords

=encoding utf8

=head1 NAME

Judoon::Lookup::Internal - Lookup data from another Judoon Dataset

=cut

use Judoon::Lookup::InternalActor;
use MooX::Types::MooseLike::Base qw(ArrayRef InstanceOf);

use Moo;
with 'Judoon::Lookup::Role::Base';
use namespace::clean;



=head1 ATTRIBUTES

=head2 dataset

An instance of L<Judoon::Schema::Result::Dataset>.

=head2 group_id

Group identifier: C<internal>

=head2 group_label

Group label: C<My Datasets>

=head2 columns

A list of simple hashrefs with metadata about the columns of the
dataset.

=cut

has '+dataset'     => (isa => InstanceOf('Judoon::Schema::Result::Dataset'));
has '+group_id'    => (is => 'ro', default => 'internal');
has '+group_label' => (is => 'ro', default => 'My Datasets');


has columns => (is => 'lazy', isa => ArrayRef[],);
sub _build_columns {
    my ($self) = @_;
    my @columns = map {{
        id    => $_->{shortname},
        label => $_->{name},
        type  => $_->{data_type},
    }} $self->dataset->ds_columns_ordered->hri->all;
    return \@columns;
}


=head1 METHODS

=head2 id

The id of the dataset.

=head2 name

The name of the dataset.

=cut

sub id { return $_[0]->dataset->id; }
sub name { return $_[0]->dataset->name; }


=head2 input_columns / output_columns / input_columns_for / output_columns_for

For Internal Lookups, these methods all return the same thing: the
list of columns in the L</columns> attribute.

=cut

sub input_columns  { return $_[0]->columns; }
sub output_columns { return $_[0]->columns; }

sub input_columns_for  { return $_[0]->columns; }
sub output_columns_for { return $_[0]->columns; }


=head2 build_actor

Builds an instance of L<Judoon::Lookup::InternalActor> capable of
performing the requested lookup.

=cut

sub build_actor {
    my ($self, $args) = @_;
    my $join_dataset = $self->user->datasets_rs->find({id => $self->id});
    return Judoon::Lookup::InternalActor->new({
        %$args, join_dataset => $join_dataset,
    });
}


1;
__END__

