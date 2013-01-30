package Judoon::Schema::Result::TtDscolumnDatatype;

=pod

=encoding utf8

=head1 NAME

Judoon::Schema::Result::TtDscolumnDatatype

=cut

use Moo;
extends 'Judoon::Schema::Result';


=head1 TABLE: C<tt_dscolumn_datatypes>

=cut

__PACKAGE__->table("tt_dscolumn_datatypes");


=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 data_type

  data_type: 'text'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
    id => {
        data_type         => "integer",
        is_auto_increment => 1,
        is_nullable       => 0,
    },
    data_type => {
        data_type      => "text",
        is_nullable    => 0,
    },
);


=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");


=head1 UNIQUE CONSTRAINTS

=head2 C<datatype_unique>

=over 4

=item * L</data_type>

=back

=cut

__PACKAGE__->add_unique_constraint(
    data_type_unique => [qw(data_type)],
);


=head1 RELATIONS

=head2 ds_columns

Type: has_many

Related object: L<Judoon::Schema::Result::DatasetColumn>

=cut

__PACKAGE__->has_many(
    ds_columns => "::DatasetColumn",
    { "foreign.data_type_id" => "self.id" },
);


1;
__END__
