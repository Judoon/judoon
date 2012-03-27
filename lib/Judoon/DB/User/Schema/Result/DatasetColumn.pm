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


has accession_types => ( is => 'ro', isa => 'ArrayRef', lazy_build => 1, );
sub _build_accession_types {
    return [
        { group_label => 'NCBI', types => [
            map {{field => $_->[0], label => $_->[1],}} (
                ['gene_id',    'Gene ID',   ],
                ['gene_name',  'Gene Name', ],
                ['refseq_id',  'RefSeq ID', ],
                ['protein_id', 'Protein ID',],
                ['unigene_id', 'UniGene ID',],
                ['pubmed_id',  'PubMed ID', ],
            )
        ], },
        { group_label => 'Uniprot', types => [
            map {{field => $_->[0], label => $_->[1],}} (
                ['uniprot_id', 'Uniprot ID'],
            )
        ], },
        { group_label => 'CritterBases', types => [
            map {{field => $_->[0], label => $_->[1],}} (
                ['flybase_id',  'FlyBase ID',  ],
                ['wormbase_id', 'WormBase ID', ],
            )
        ], },
    ];
}

has linkthings => ( is => 'ro', isa => 'HashRef', lazy_build => 1, );
sub _build_linkthings {
    return {
    gene_name  => {label => '', links => [
        {
            value=>'gene',
            text=>'Entrez Gene',
            example=>'http://www.ncbi.nlm.nih.gov/gene/7094',
            prefix=>'http://www.ncbi.nlm.nih.gov/gene/',
            postfix=>'',
        },
        {
            value=>'uniprot',
            text=>'Uniprot',
            example=>'http://www.uniprot.org/uniprot/Q9Y490',
            prefix=>'http://www.uniprot.org/uniprot/',
            postfix=>'',
        },
        {
            value=>'cmkb',
            text=>'Cell Migration KnowledgeBase',
            example=>'http://cmckb.cellmigration.org/gene/?gene_name=TLN1',
            prefix=>'http://cmckb.cellmigration.org/gene/?gene_name=',
            postfix=>'',
        },
        {
            value=>'omim',
            text=>'OMIM',
            example=>'http://www.ncbi.nlm.nih.gov/omim/186745',
            prefix=>'http://www.ncbi.nlm.nih.gov/omim/',
            postfix=>'',
        },
        {
            value=>'pfam',
            text=>'PFAM',
            example=>'http://pfam.sanger.ac.uk/protein?acc=Q9Y490',
            prefix=>'http://pfam.sanger.ac.uk/protein?acc=',
            postfix=>'',
        },
        {
            value=>'addgene',
            text=>'AddGene',
            example=>'http://www.addgene.org/pgvec1?f=c&cmd=showgene&geneid=7094',
            prefix=>'http://www.addgene.org/pgvec1?f=c&cmd=showgene&geneid=',
            postfix=>'',
        },
        {
            value=>'kegg',
            text=>'KEGG',
            example=>'http://www.genome.jp/dbget-bin/www_bget?hsa:7094',
            prefix=>'http://www.genome.jp/dbget-bin/www_bget?hsa:',
            postfix=>'',
        },
    ],},
    flybase_id => {label => '', links => [
        {
            value => 'flybase',
            text => 'FlyBase',
            example => 'http://flybase.bio.indiana.edu/.bin/fbidq.html?FBgn0025725',
            prefix => 'http://flybase.bio.indiana.edu/.bin/fbidq.html?',
            postfix=>'',
        },
    ],},
    unigene_id => {
        label => '',
        links => [
        {
            value=>'unigene',
            text=>'UniGene',
            example=>'http://www.ncbi.nlm.nih.gov/unigene/686173',
            prefix=>'http://www.ncbi.nlm.nih.gov/unigene/',
            postfix=>'',
        },
    ],},
};
}


before 'insert' => sub {
    my ($self, $args) = @_;

    if (not $args->{shortname}) {
        (my $shortname = lc($args->{name} || 'nothing')) =~ s/[^0-9a-z_]/_/g;
        $shortname ||= 'empty';
        $args->{shortname} = $shortname;
    }
    return;
};


sub linkset {
    my ($self) = @_;

    my @links;
    if ($self->is_accession) {
        @links = @{$self->linkthings->{$self->accession_type}->{links}}
    }
    elsif ($self->is_url) {
        @links = 'something else?';
    }

}


sub get_linksites {
    my ($self) = @_;

    my %new_struct;
    for my $t (values %{$self->linkthings}) {
        for my $l (@{$t->{links}}) {
            $new_struct{$l->{value}} = $l;
        }
    }

    return \%new_struct;
}



__PACKAGE__->meta->make_immutable;
1;
