package Judoon::Schema::Result::DatasetColumn;

=pod

=encoding utf8

=head1 NAME

Judoon::Schema::Result::DatasetColumn

=cut

use Judoon::Schema::Candy;
use Moo;


table 'dataset_columns';


primary_column id => {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
};
column dataset_id => {
    data_type      => "integer",
    is_foreign_key => 1,
    is_nullable    => 0,
};
column name => {
    data_type       => "text",
    is_nullable     => 0,
    is_serializable => 1,
};
column shortname => {
    data_type       => "text",
    is_nullable     => 1,
    is_serializable => 1,
};
column sort => {
    data_type   => "integer",
    is_nullable => 0,
};
column data_type_id => {
    data_type      => "integer",
    is_foreign_key => 1,
    is_nullable    => 0,
};
column accession_type_id => {
    data_type      => "integer",
    is_foreign_key => 1,
    is_nullable    => 1,
};


unique_constraint dataset_id_shortname_unique => [qw(dataset_id shortname)];
unique_constraint dataset_id_name_unique => [qw(dataset_id name)];

belongs_to dataset => "::Dataset",
    { id => "dataset_id" },
    { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" };

belongs_to data_type_rel => "::TtDscolumnDatatype",
    { "foreign.id" => "self.data_type_id" },
    {
        lookup_proxy => 'data_type',
        is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE",
    };

belongs_to accession_type_rel => "::TtAccessionType",
    { "foreign.id" => "self.accession_type_id" },
    {
        join_type     => 'left',
        lookup_proxy  => 'accession_type',
        is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE",
    };


=head1 EXTRA COMPONENTS

=head2 Ordered

C<DatasetColumns> are ordered by the C<sort> column, grouped by
C<dataset_id>.

=cut

__PACKAGE__->load_components(qw(Ordered));
__PACKAGE__->position_column('sort');
__PACKAGE__->grouping_column('dataset_id');


=head2 ::Role::Result::HasTimestamps

Add <created> and <modified> columns to C<DatasetColumn>.

=cut

with qw(Judoon::Schema::Role::Result::HasTimestamps);
__PACKAGE__->register_timestamps;


sub TO_JSON {
    my ($self) = @_;
    my $json = $self->next::method();
    $json->{data_type} = $self->data_type;
    $json->{accession_type} = $self->accession_type;
    return $json;
}


1;
