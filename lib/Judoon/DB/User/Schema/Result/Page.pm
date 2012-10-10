use utf8;
package Judoon::DB::User::Schema::Result::Page;

=head1 NAME

Judoon::DB::User::Schema::Result::Page

=cut

use Moo;
extends 'DBIx::Class::Core';

=head1 TABLE: C<pages>

=cut

__PACKAGE__->table("pages");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 dataset_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 title

  data_type: 'text'
  is_nullable: 0

=head2 preamble

  data_type: 'text'
  is_nullable: 0

=head2 postamble

  data_type: 'text'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "dataset_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "title",
  { data_type => "text", is_nullable => 0 },
  "preamble",
  { data_type => "text", is_nullable => 0 },
  "postamble",
  { data_type => "text", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 dataset

Type: belongs_to

Related object: L<Judoon::DB::User::Schema::Result::Dataset>

=cut

__PACKAGE__->belongs_to(
  "dataset",
  "Judoon::DB::User::Schema::Result::Dataset",
  { id => "dataset_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 page_columns

Type: has_many

Related object: L<Judoon::DB::User::Schema::Result::PageColumn>

=cut

__PACKAGE__->has_many(
  "page_columns",
  "Judoon::DB::User::Schema::Result::PageColumn",
  { "foreign.page_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 1 },
);


=pod

=encoding utf8

=cut

with qw(Judoon::DB::User::Schema::Role::Result::HasPermissions);
__PACKAGE__->register_permissions;


=head2 nbr_columns

Number of columns in this dataset.

=cut

sub nbr_columns {
    my ($self) = @_;
    my @columns = $self->page_columns;
    return scalar @columns;
}


=head2 nbr_rows

Number of rows in this dataset.

=cut

sub nbr_rows {
    my ($self) = @_;
    return $self->dataset->nbr_rows;
}


1;
