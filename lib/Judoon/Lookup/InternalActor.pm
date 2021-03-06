package Judoon::Lookup::InternalActor;

use MooX::Types::MooseLike::Base qw(InstanceOf);

use Moo;
with 'Judoon::Lookup::Role::Actor';
use namespace::clean;


has join_dataset => (
    is       => 'ro',
    isa      => InstanceOf['Judoon::Schema::Result::Dataset'],
    required => 1,
);


sub validate_args {
    my ($self) = @_;
    return
        $self->_ds_has_column( $self->that_joincol_id )
        &&
        $self->_ds_has_column( $self->that_selectcol_id );
}

sub _ds_has_column {
    my ($self, $col_shortname) = @_;
    return $self->join_dataset->ds_columns_rs->find({shortname => $col_shortname}) ? 1 : 0;
}

sub result_data_type {
    my ($self, $attrs) = @_;
    return $self->join_dataset->ds_columns_rs->find({
        shortname => $self->that_selectcol_id,
    })->data_type;
}

sub lookup {
    my ($self, $col_data) = @_;

    my $data = $self->join_dataset->column_data(
        $self->that_joincol_id, $self->that_selectcol_id,
    );

    my %data_map;
    for my $data_pair (@$data) {
        push @{ $data_map{$data_pair->[0]} },
            $data_pair->[1];
    }
    for my $key (keys %data_map) {
        $data_map{$key} = join ', ', @{ $data_map{$key} };
    }

    return [map {$data_map{$_} // ''} @$col_data];
    # SELECT $to_column
    # FROM $from_dataset
    #   JOIN $join_dataset ON $from_column=$join_column
}


1;
__END__

=pod

=for stopwords

=encoding utf8

=head1 NAME

Judoon::Lookup::InternalActor - Base class of Judoon dataset lookups

=head1 DESCRIPTION

This is our base class for internal database lookup actors.  Lookup
actors are the objects in charge of actually taking a list of data and
translating that into new data via lookups in another data
source. Objects of this class are expected to fetch their data from a
another Judoon dataset.

These objects are constructed by the C<build_actor()> method of a
L<Judoon::Lookup::Internal> object.

=head1 REQUIRED ATTRIBUTES

=head2 join_dataset

An instance of L<Judoon::Schema::Result::Dataset> that new new data
will be retrieved from.

=head1 METHODS

=head2 validate_args()

Validates that both C<that_joincol_id> and C<that_selectcol_id> are
valid C<shortname>s for C<DatasetColumn>s in C<join_dataset>.

=head2 result_data_type

The L<Judoon::Type> of the output data.

=head2 lookup(\@col_data)

For each entry in C<@col_data>, find a matching entry in
C<join_dataset>.C<that_joincol_id>, and return the related data in
C<join_dataset>.C<that_selectcol_id>.

=head1 AUTHOR

Fitz ELLIOTT <felliott@fiskur.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by the Rector and Visitors of the
University of Virginia.

This is free software, licensed under:

 The Artistic License 2.0 (GPL Compatible)

=cut
