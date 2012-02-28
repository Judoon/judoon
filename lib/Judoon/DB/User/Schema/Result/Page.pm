use utf8;
package Judoon::DB::User::Schema::Result::Page;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Judoon::DB::User::Schema::Result::Page

=cut

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
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
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07017 @ 2012-02-28 16:31:02
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Npdwxhg8ICnYH03OCefyVg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
