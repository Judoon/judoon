use utf8;
package Judoon::Schema::Result::User;

=pod

=encoding utf8

=head1 NAME

Judoon::Schema::Result::User

=cut

use Moo;
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

Related object: L<Judoon::Schema::Result::Dataset>

=cut

__PACKAGE__->has_many(
  "datasets",
  "Judoon::Schema::Result::Dataset",
  { "foreign.user_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 user_roles

Type: has_many

Related object: L<Judoon::Schema::Result::UserRole>

=cut

__PACKAGE__->has_many(
  "user_roles",
  "Judoon::Schema::Result::UserRole",
  { "foreign.user_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 roles

Type: many_to_many

Composing rels: L</user_roles> -> role

=cut

__PACKAGE__->many_to_many("roles", "user_roles", "role");


use Judoon::Spreadsheet;


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


=head1 METHODS

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

C<import_data()> takes in a filehandle arg and attempts to turn it into
a L<Judoon::Spreadsheet>.  It will then munge the data and insert it
into the database.

=cut

sub import_data {
    my ($self, $fh, $ext) = @_;
    die 'import_data() needs a filehandle' unless ($fh);

    my $spreadsheet = Judoon::Spreadsheet->new(
        filehandle => $fh, filetype => $ext,
    );
    my $dataset = $self->create_related('datasets',{
        map({$_ => q{}} qw(name tablename original notes)),
        map({$_ => 0}   qw(nbr_rows nbr_columns)),
    });
    $dataset->import_from_spreadsheet($spreadsheet);
    return $dataset;
}


sub import_data_by_filename {
    my ($self, $filename) = @_;

    open my $SPREADSHEET, '<', $filename
         or die "Can't open test spreadsheet: $!";
    (my $ext = $filename) =~ s/^.*\.//;
    my $new_ds = $self->import_data($SPREADSHEET, $ext);
    close $SPREADSHEET;
    return $new_ds;
}


sub my_pages {
    my ($self, $args) = @_;
    return $self->datasets_rs->related_resultset('pages');
}

1;