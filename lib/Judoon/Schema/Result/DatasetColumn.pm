package Judoon::Schema::Result::DatasetColumn;

=pod

=encoding utf8

=head1 NAME

Judoon::Schema::Result::DatasetColumn

=cut

use Moo;
extends 'Judoon::Schema::Result';


=head1 TABLE: C<dataset_columns>

=cut

__PACKAGE__->table("dataset_columns");


=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 dataset_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 name

  data_type: 'text'
  is_nullable: 0

=head2 shortname

  data_type: 'text'
  is_nullable: 1

=head2 sort

  data_type: 'integer'
  is_nullable: 0

=head2 data_type_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 accession_type_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
    id => {
        data_type         => "integer",
        is_auto_increment => 1,
        is_nullable       => 0,
    },
    dataset_id => {
        data_type      => "integer",
        is_foreign_key => 1,
        is_nullable    => 0,
    },
    name => {
        data_type   => "text",
        is_nullable => 0,
    },
    shortname => {
        data_type   => "text",
        is_nullable => 1,
    },
    sort => {
        data_type   => "integer",
        is_nullable => 0,
    },
    data_type_id => {
        data_type      => "integer",
        is_foreign_key => 1,
        is_nullable    => 0,
    },
    accession_type_id => {
        data_type      => "integer",
        is_foreign_key => 1,
        is_nullable    => 1,
    },
);


=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");


=head1 UNIQUE CONSTRAINTS

=head2 C<dataset_id_shortname_unique>

=over 4

=item * L</dataset_id>, L</shortname>

=back

=cut

__PACKAGE__->add_unique_constraint(
    dataset_id_shortname_unique => [qw(dataset_id shortname)],
);

=head2 C<dataset_id_name_unique>

=over 4

=item * L</dataset_id>, L</name>

=back

=cut

__PACKAGE__->add_unique_constraint(
    dataset_id_name_unique => [qw(dataset_id name)],
);


=head1 RELATIONS

=head2 dataset

Type: belongs_to

Related object: L<Judoon::Schema::Result::Dataset>

=cut

__PACKAGE__->belongs_to(
    dataset => "::Dataset",
    { id => "dataset_id" },
    { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


=head2 data_type_rel

Type: belongs_to

Related object: L<Judoon::Schema::Result::TtDscolumnDatatype>

=cut

__PACKAGE__->belongs_to(
    data_type_rel => "::TtDscolumnDatatype",
    { "foreign.id" => "self.data_type_id" },
    {
        lookup_proxy => 'data_type',
        is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE",
    },
);


=head3 accession_type_id

Type: belongs_to

Related object: L<Judoon::Schema::Result::TtAccessionType>

=cut

__PACKAGE__->belongs_to(
    accession_type_rel => "::TtAccessionType",
    { "foreign.id" => "self.accession_type_id" },
    {
        join_type     => 'left',
        lookup_proxy  => 'accession_type',
        is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE",
    },
);



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



1;
