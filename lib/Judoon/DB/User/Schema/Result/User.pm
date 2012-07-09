use utf8;
package Judoon::DB::User::Schema::Result::User;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

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

=head2 active

  data_type: 'char'
  is_nullable: 0
  size: 1

=head2 username

  data_type: 'text'
  is_nullable: 0

=head2 password

  data_type: 'text'
  is_nullable: 0

=head2 password_expires

  data_type: 'timestamp'
  is_nullable: 1

=head2 name

  data_type: 'text'
  is_nullable: 0

=head2 email_address

  data_type: 'text'
  is_nullable: 0

=head2 phone_number

  data_type: 'text'
  is_nullable: 1

=head2 mail_address

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "active",
  { data_type => "char", is_nullable => 0, size => 1 },
  "username",
  { data_type => "text", is_nullable => 0 },
  "password",
  { data_type => "text", is_nullable => 0 },
  "password_expires",
  { data_type => "timestamp", is_nullable => 1 },
  "name",
  { data_type => "text", is_nullable => 0 },
  "email_address",
  { data_type => "text", is_nullable => 0 },
  "phone_number",
  { data_type => "text", is_nullable => 1 },
  "mail_address",
  { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<username_unique>

=over 4

=item * L</username>

=back

=cut

__PACKAGE__->add_unique_constraint("username_unique", ["username"]);

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

=head2 user_roles

Type: has_many

Related object: L<Judoon::DB::User::Schema::Result::UserRole>

=cut

__PACKAGE__->has_many(
  "user_roles",
  "Judoon::DB::User::Schema::Result::UserRole",
  { "foreign.user_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 roles

Type: many_to_many

Composing rels: L</user_roles> -> role

=cut

__PACKAGE__->many_to_many("roles", "user_roles", "role");


# Created by DBIx::Class::Schema::Loader v0.07024 @ 2012-05-15 22:15:38
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:SzGqoNkBtKX9SumB+vTVCw

__PACKAGE__->load_components('PassphraseColumn');
__PACKAGE__->add_columns(
    '+password' => {
        passphrase       => 'rfc2307',
        passphrase_class => 'BlowfishCrypt',
        passphrase_args  => {
            cost        => 8,
            salt_random => 20,
        },
        passphrase_check_method => 'check_password',
    }
);


use Spreadsheet::Read ();

=head2 B<C<change_password( $password )>>

Validates and sets password

=cut

sub change_password {
    my ($self, $newpass) = @_;
    die 'Invalid password.' unless ($self->result_source->resultset->validate_password($newpass));
    $self->password($newpass);
    $self->update;
}


=head2 import_data( $filehandle )

C<import_data()> takes in a filehandle arg and attempts to read it
with L<Spreadsheet::Read>.  It will then munge the data and insert it
into the database.

=cut

sub import_data {
    my ($self, $fh) = @_;
    die 'import_data() needs a filehandle' unless ($fh);

    my $ref  = Spreadsheet::Read::ReadData($fh, parser => 'xls');

    my $ds   = $ref->[1];
    my $data = $self->pivot_data($ds->{cell}, $ds->{maxrow}, $ds->{maxcol});

    my $dataset = $self->create_related('datasets', {
        name => $ds->{label}, original => q{},
        data => $data, notes => q{},
    });

    my $headers = shift @$data;
    my $sort = 1;
    for my $header (@$headers) {
        $dataset->create_related('ds_columns', {
            name => ($header // ''), sort => $sort++,
            accession_type => q{},   url_root => q{},
        });
    }

    return $dataset;
}


=head2 pivot_data( $data, $maxrow, $maxcol )

C<pivot_data()> takes an arrayref of arrayrefs as C<$data> and pivots
it to be row-major instead of colulmn-major.  It also removes the
empty leading entries L<Spreadsheet::Read> adds so that it is
zero-indexed instead of one-indexed.

C<$maxrow> and C<$maxcol> are the maximum number of rows and columns
respectively.  While these could be calculated dynamically,
L<Spreadsheet::Read> provides them, and requiring them simplifies the
code.

=cut

sub pivot_data {
    my ($self, $data, $maxrow, $maxcol) = @_;

    my $pivoted = [];
    for my $row_idx (0..$maxrow-1) {
        for my $col_idx (0..$maxcol-1) {
            $pivoted->[$row_idx][$col_idx] = $data->[$col_idx+1][$row_idx+1];
        }
    }

    return $pivoted;
}



__PACKAGE__->meta->make_immutable;
1;
