use utf8;
package Judoon::DB::User::Schema::Result::UserRole;

=head1 NAME

Judoon::DB::User::Schema::Result::UserRole

=cut

use Moo;
extends 'DBIx::Class::Core';

=head1 TABLE: C<user_roles>

=cut

__PACKAGE__->table("user_roles");

=head1 ACCESSORS

=head2 user_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 role_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "user_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "role_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</user_id>

=item * L</role_id>

=back

=cut

__PACKAGE__->set_primary_key("user_id", "role_id");

=head1 RELATIONS

=head2 role

Type: belongs_to

Related object: L<Judoon::DB::User::Schema::Result::Role>

=cut

__PACKAGE__->belongs_to(
  "role",
  "Judoon::DB::User::Schema::Result::Role",
  { id => "role_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
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



=pod

=encoding utf8

=cut

1;
