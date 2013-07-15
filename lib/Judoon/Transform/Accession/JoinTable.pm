package Judoon::Transform::Accession::JoinTable;

use Moo;
use MooX::Types::MooseLike::Base qw(Str InstanceOf);

with 'Judoon::Transform::Role::Base',
     'Judoon::Transform::Role::OneInput';

sub result_data_type      { return 'text'; }
sub result_accession_type { return undef;  }

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
