package Judoon::Schema::Result::DatasetColumn;

=pod

=encoding utf8

=head1 NAME

Judoon::Schema::Result::DatasetColumn

=cut

use Judoon::Schema::Candy;
use Moo;

use MooX::Types::MooseLike::Base qw(InstanceOf);
use Judoon::TypeRegistry;


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
column data_type => {
    data_type       => "text",
    is_nullable     => 0,
    is_foreign_key  => 1,
    is_serializable => 1,
};


unique_constraint dataset_id_shortname_unique => [qw(dataset_id shortname)];
unique_constraint dataset_id_name_unique => [qw(dataset_id name)];

belongs_to dataset => "::Dataset",
    { id => "dataset_id" },
    { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" };

belongs_to type_check => "::TtDscolumnDatatype",
    { data_type => "data_type" },
    { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" };



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


=head2 InflateColumn

The C<data_type> field of C<DatasetColumn> will be inflated to a
L<Judoon::Type> object when C<< $page_column->template() >> is
called. Use C<< ->get_column('template') >> to get the raw data.

=cut

__PACKAGE__->inflate_column('data_type', {
    inflate => sub {
        my ($type_id, $self) = @_;
        return $self->type_registry->simple_lookup($type_id);
    },
    deflate => sub { shift->name },
});


=head1 ATTRIBUTES

=head2 type_registry

An instance of L<Judoon::TypeRegistry> that we use to turn the
C<data_type> field into L<Judoon::Type> objects.

=cut

has type_registry => (
    is  => 'lazy',
    isa => InstanceOf['Judoon::TypeRegistry'],
);
sub _build_type_registry { return Judoon::TypeRegistry->new; }


=head1 METHODS

=head2 TO_JSON

Serialize this object into a JSON string.

=cut

sub TO_JSON {
    my ($self) = @_;
    my $tmp = $self->next::method();
    $tmp->{data_type}   = $tmp->{data_type}->name;
    my $shortname       = $tmp->{shortname};
    $tmp->{sample_data} = $self->dataset->sample_data(3, $shortname)->{$shortname};
    return $tmp;
}


1;
