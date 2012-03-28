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




use Spreadsheet::Read ();



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
