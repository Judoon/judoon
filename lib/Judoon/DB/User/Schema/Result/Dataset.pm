use utf8;
package Judoon::DB::User::Schema::Result::Dataset;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Judoon::DB::User::Schema::Result::Dataset

=cut

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

=head1 TABLE: C<datasets>

=cut

__PACKAGE__->table("datasets");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 user_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 name

  data_type: 'text'
  is_nullable: 0

=head2 notes

  data_type: 'text'
  is_nullable: 0

=head2 original

  data_type: 'text'
  is_nullable: 0

=head2 data

  data_type: 'text'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "user_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "name",
  { data_type => "text", is_nullable => 0 },
  "notes",
  { data_type => "text", is_nullable => 0 },
  "original",
  { data_type => "text", is_nullable => 0 },
  "data",
  { data_type => "text", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 columns_rel

Type: has_many

Related object: L<Judoon::DB::User::Schema::Result::Column>

=cut

__PACKAGE__->has_many(
  "columns_rel",
  "Judoon::DB::User::Schema::Result::Column",
  { "foreign.dataset_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 pages

Type: has_many

Related object: L<Judoon::DB::User::Schema::Result::Page>

=cut

__PACKAGE__->has_many(
  "pages",
  "Judoon::DB::User::Schema::Result::Page",
  { "foreign.dataset_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 user

Type: belongs_to

Related object: L<Judoon::DB::User::Schema::Result::User>

=cut

__PACKAGE__->belongs_to(
  "user",
  "Judoon::DB::User::Schema::Result::User",
  { id => "user_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07017 @ 2012-02-28 16:31:02
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:1gZ/aUt3NXOZRDv1/X1rDw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
