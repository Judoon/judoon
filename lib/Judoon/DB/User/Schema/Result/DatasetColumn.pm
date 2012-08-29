use utf8;
package Judoon::DB::User::Schema::Result::DatasetColumn;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Judoon::DB::User::Schema::Result::DatasetColumn

=cut

use Moo;
extends 'DBIx::Class::Core';

=head1 TABLE: C<dataset_columns>

=cut

__PACKAGE__->table("dataset_columns");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 dataset_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 name

  data_type: 'text'
  is_nullable: 0

=head2 sort

  data_type: 'integer'
  is_nullable: 0

=head2 is_accession

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 accession_type

  data_type: 'text'
  is_nullable: 0

=head2 is_url

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 url_root

  data_type: 'text'
  is_nullable: 0

=head2 shortname

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "dataset_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "name",
  { data_type => "text", is_nullable => 0 },
  "sort",
  { data_type => "integer", is_nullable => 0 },
  "is_accession",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "accession_type",
  { data_type => "text", is_nullable => 0 },
  "is_url",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "url_root",
  { data_type => "text", is_nullable => 0 },
  "shortname",
  { data_type => "text", is_nullable => 1 },
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


# Created by DBIx::Class::Schema::Loader v0.07024 @ 2012-05-15 21:44:31
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:AjdNiBkWSaIe1b1bk6VjNQ


=pod

=encoding utf8

=cut

use Judoon::SiteLinker;
has sitelinker => (is => 'lazy',); # isa => 'Judoon::SiteLinker',);
sub _build_sitelinker { return Judoon::SiteLinker->new; }


=head2 linkset()

Return a list of linkable sites via Judoon::SiteLinker

=cut

sub linkset {
    my ($self) = @_;

    my @links;
    if ($self->is_accession) {
        my $sites = $self->sitelinker->mapping->{accession}{$self->accession_type};
        for my $site (keys %$sites) {
            my $site_conf = $self->sitelinker->sites->{$site};
            push @links, {
                value   => $site_conf->{name},
                example => '',
                text    => $site_conf->{label},
            };
        }
    }
    elsif ($self->is_url) {
        @links = 'something else?';
    }


    return \@links;
}


=head2 C<B<delete_column>>

C<delete_column> deletes not just the DatasetColumn itself (which
actually represents the column header), but the actual column of data
in the Dataset.

You should probably call this instead of C<delete>, or else your data
and data headers will be out of sync.  Also, if you have a reference
to the parent dataset, make sure to call C<< ->discard_changes() >> on
it, or the column data will be incorrect.

=cut

sub delete_column {
    my ($self) = @_;
    my $pos = $self->ordinal_position;
    $self->dataset->delete_data_columns($pos);
    return $self->delete;
}


=head2 C<B<ordinal_position>>

Get the ordinal position of this column in the set of related columns.
The C<sort> column maintains the sort order, but is not necessarily the
actual ordinal position.

=cut

sub ordinal_position {
    my ($self) = @_;
    return $self->result_source->resultset
        ->ordinal_position_for($self->dataset_id, $self->sort);
}


1;
