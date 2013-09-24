package Judoon::Lookup::InternalActor;

use MooX::Types::MooseLike::Base qw(InstanceOf);

use Moo;

with 'Judoon::Lookup::Role::Actor';

has join_dataset => (
    is       => 'ro',
    isa      => InstanceOf['Judoon::Schema::Result::Dataset'],
    required => 1,
);


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
