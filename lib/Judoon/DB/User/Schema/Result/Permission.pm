use utf8;
package Judoon::DB::User::Schema::Result::Permission;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Judoon::DB::User::Schema::Result::Permission

=cut

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

=head1 TABLE: C<permissions>

=cut

__PACKAGE__->table("permissions");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 obj_id

  data_type: 'integer'
  is_nullable: 0

=head2 permission

  data_type: 'text'
  is_nullable: 0

=head2 password

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "obj_id",
  { data_type => "integer", is_nullable => 0 },
  "permission",
  { data_type => "text", is_nullable => 0 },
  "password",
  { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<obj_id_unique>

=over 4

=item * L</obj_id>

=back

=cut

__PACKAGE__->add_unique_constraint("obj_id_unique", ["obj_id"]);


# Created by DBIx::Class::Schema::Loader v0.07025 @ 2012-07-12 10:42:15
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:It4yzrDVyyvCeL4wTLd0ng


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
