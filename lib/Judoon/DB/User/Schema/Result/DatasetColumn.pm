use utf8;
package Judoon::DB::User::Schema::Result::DatasetColumn;

=head1 NAME

Judoon::DB::User::Schema::Result::DatasetColumn

=cut

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

=head1 TABLE: C<columns>

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


# from MooseX::NonMoose, lets us preprocess the args to new()
sub FOREIGNBUILDARGS {
    my ($class, $args) = @_;

    if (not $args->{shortname}) {
        (my $shortname = lc($args->{name} || 'nothing')) =~ s/[^0-9a-z_]/_/g;
        $shortname ||= 'empty';
        $args->{shortname} = $shortname;
    }

    return $args;
}

use Judoon::SiteLinker;
has sitelinker => (is => 'ro', isa => 'Judoon::SiteLinker', lazy_build => 1);
sub _build_sitelinker { return Judoon::SiteLinker->new; }


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





__PACKAGE__->meta->make_immutable;
1;
