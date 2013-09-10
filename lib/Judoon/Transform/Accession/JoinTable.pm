package Judoon::Transform::Accession::JoinTable;

use Moo;
use MooX::Types::MooseLike::Base qw(Str InstanceOf);

with 'Judoon::Transform::Role::Base',
     'Judoon::Transform::Role::OneInput';

has join_dataset => (
    is       => 'ro',
    required => 1,
    isa      => InstanceOf('Judoon::Schema::Result::Dataset'),
);

has join_column => (
    is       => 'ro',
    required => 1,
    isa      => Str,
);

has to_column => (
    is       => 'ro',
    required => 1,
    isa      => Str,
);


sub result_data_type {
    my ($self) = @_;
    return $self->join_dataset->ds_columns_rs->find({
        shortname => $self->to_column
    })->data_type;
}

sub apply_batch {
    my ($self, $col_data) = @_;

    my $data = $self->join_dataset->column_data(
        $self->join_column, $self->to_column,
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

=encoding utf8

=head1 NAME

Judoon::Transform::Accession::JoinTable - Lookup value from another table

=head1 DESCRIPTION

Placeholder documentation

=head1 METHODS

=head2 result_data_type

C<CoreType_Text>

=head2 apply_batch

The subroutine that performs the transform.

=head2 join_column / join_dataset / to_column

=cut
