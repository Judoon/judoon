use utf8;
package Judoon::DB::User::Schema::Result::Permission;

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

=head2 pk

  data_type: 'serial'
  is_nullable: 0

=head2 obj_fk

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


__PACKAGE__->add_unique_constraint("obj_id_unique", ["obj_id"]);



__PACKAGE__->meta->make_immutable;
1;
