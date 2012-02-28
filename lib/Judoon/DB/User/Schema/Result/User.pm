use utf8;
package Judoon::DB::User::Schema::Result::User;

=head1 NAME

Judoon::DB::User::Schema::Result::User

=cut

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

=head1 TABLE: C<users>

=cut

__PACKAGE__->table("users");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 login

  data_type: 'text'
  is_nullable: 0

=head2 name

  data_type: 'text'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "login",
  { data_type => "text", is_nullable => 0 },
  "name",
  { data_type => "text", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<login_unique>

=over 4

=item * L</login>

=back

=cut

__PACKAGE__->add_unique_constraint("login_unique", ["login"]);

=head1 RELATIONS

=head2 datasets

Type: has_many

Related object: L<Judoon::DB::User::Schema::Result::Dataset>

=cut

__PACKAGE__->has_many(
  "datasets",
  "Judoon::DB::User::Schema::Result::Dataset",
  { "foreign.user_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);



__PACKAGE__->meta->make_immutable;
1;
