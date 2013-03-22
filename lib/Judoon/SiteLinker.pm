package Judoon::SiteLinker;

=pod

=for stopwords vice-versa

=encoding utf8

=head1 NAME

Judoon::SiteLinker - Utility class for mapping accessions to websites

=head1 SYNOPSIS

 use Judoon::SiteLinker;

 my $sitelinker = Judoon::SiteLinker->new;

 my $mapping = $sitelinker->mapping->{site}{pfam}{uniprot_acc}
 # $mapping->{prefix} == 'http://pfam.sanger.ac.uk/protein?acc='

=head1 DESCRIPTION

This module simply provides a bunch of data structures to map
accessions to websites and vice-versa.

=cut

use Moo;
use MooX::Types::MooseLike::Base qw(HashRef ArrayRef);

use List::AllUtils qw(zip);

=head1 ATTRIBUTES

=head2 C<B<sites / _build_sites>>

C<sites> is a hashref of website properties keyed off the website
identifier.  The properties have the following structure:

 {name => $website_id, label => $descriptive_name}
 e.g. {name => 'gene', label => 'Entrez Gene',}

=cut

has sites => (is => 'lazy', isa => HashRef,);
sub _build_sites {
    my ($self) = @_;

    my @sites = (
        # name  label
        ['gene',     'Entrez Gene',],
        ['cmkb',     'Cell Migration KnowledgeBase',],
        ['uniprot',  'Uniprot',],
        ['pfam',     'Pfam',],
        ['addgene',  'AddGene',],
        ['kegg',     'KEGG',],
        ['flybase',  'FlyBase',],
        ['wormbase', 'WormBase',],
        ['unigene',  'Unigene',],
    );
    my @keys = qw(name label);

    return {
        map {$_->[0] => {zip @keys, @$_}} @sites
    };
}


=head2 B<C<accessions / _build_accessions>>

C<accessions> is a hashref of accession properties keyed off the
accession identifier.  The property structure is:

 {name => $acc_id, label => $descriptive_name, example => $example_accession}
 e.g. {name => 'uniprot_id', label => 'UniprotID', example => 'TLN1_HUMAN',}

=cut

has accessions => (is => 'lazy', isa => HashRef,);
sub _build_accessions {
    my ($self) = @_;

    my @accs = (
        # name label example
        ['entrez_gene_id',     'Entrez Gene ID',     '7094',           ],
        ['entrez_gene_symbol', 'Entrez Gene Symbol', 'TLN1',           ],
        ['entrez_refseq_id',   'RefSeq ID',          'NM_006289',      ],
        ['entrez_protein_id',  'Entrez Protein ID',  'NP_006280',      ],
        ['entrez_unigene_id',  'Entrez Unigene ID',  '686173',         ],
        ['pubmed_id',          'PubMed ID',          '22270917',       ],
        ['uniprot_acc',        'Uniprot ACC',        'Q9Y490',         ],
        ['uniprot_id',         'Uniprot ID',         'TLN1_HUMAN',     ],
        ['flybase_id',         'FlyBase ID',         'FBgn0041789',    ],
        ['wormbase_id',        'WormBase ID',        'WBGene00016197', ],
#        [],
    );
    my @keys = qw(name label example);

    return {
        map {$_->[0] => {zip @keys, @$_}} @accs
    };
}


=head2 B<C<mapping / _build_mapping>>

C<mapping> holds the specific properties of how to link a particular
accession to a particular website.  It's a hashref with two subkeys,
C<site> and C<accession>, to allow bidirectional lookups of
properties. Ex. given C<$site> and C<$accession>, you can get link
properties either by:

 $sitelinker->mapping->{site}{$site}{$accession}
 $sitelinker->mapping->{accession}{$accession}{$site}

The resulting link properties have the following structure:

 {
  prefix => $link_prefix, postfix => $link_postfix,
  exact => 1, one_to_many => 0,
 }
 e.g. for ->mapping->{site}{pfam}{uniprot_acc}
 {
  prefix      => 'http://www.ncbi.nlm.nih.gov/unigene/',
  postfix     => '',
  exact       => 1,
  one_to_many => 0,
 }

The current property list is:

=over

=item C<prefix> / C<postfix>

C<prefix> and C<postfix> are strings which when prepended and appended
to the accession, will produce a valid link to the website.

=item C<exact>

C<exact> is a boolean flag that when true implies that this accession
will link to an exact record in the mapped website.  If C<exact> is
false, the url may produce zero, one, or more records.

=item C<one_to_many>

C<one_to_many> implies that the given accession / site mapping will
produce a url that links to multiple resources. e.g. linking Entrez
Protein with an Entrez Gene id.

=back

=cut

has mapping => (is => 'lazy', isa => HashRef,);
sub _build_mapping {
    my ($self) = @_;

    my @maps = (
        # site accession text_segs exact one-to-many example_data
        ['cmkb',    'entrez_gene_id', ['http://cmckb.cellmigration.org/gene/',],            1, 0,],
        ['cmkb',    'entrez_gene_symbol', ['http://cmckb.cellmigration.org/search?search_type=name_acc&keyword=',], 0, 0],
        ['flybase', 'flybase_id',     ['http://flybase.bio.indiana.edu/.bin/fbidq.html?',], 1, 0,],
        ['gene',    'entrez_gene_id', ['http://www.ncbi.nlm.nih.gov/gene/',''],             1, 0,],
        ['gene',    'entrez_gene_symbol', ['http://www.ncbi.nlm.nih.gov/gene?term=',],      0, 0,],
        ['kegg',    'entrez_gene_id', ['http://www.genome.jp/dbget-bin/www_bget?hsa:',],    1, 0,],
        ['pfam',    'uniprot_acc',    ['http://pfam.sanger.ac.uk/protein?acc=',],           1, 0,],
        ['unigene', 'entrez_unigene_id',     ['http://www.ncbi.nlm.nih.gov/unigene/',],            1, 0,],
        ['uniprot', 'uniprot_acc',    ['http://www.uniprot.org/uniprot/',''],               1, 0,],
        ['wormbase', 'wormbase_id',   ['http://www.wormbase.org/db/gene/gene?class=CDS;name=',], 1, 0,],
    );

    my %mappings = (site => {}, accession => {});
    for my $map (@maps) {
        my ($site, $acc, $text_segs, $exact, $o2m) = @$map;
        my $link_map = {
            prefix      => $text_segs->[0],
            postfix     => $text_segs->[1] // '',
            exact       => $exact,
            one_to_many => $o2m,
        };
        $mappings{site}{$site}{$acc}      = $link_map;
        $mappings{accession}{$acc}{$site} = $link_map;
    }

    return \%mappings;
}


=head2 B<C<accession_groups / _build_accession_groups>>

C<accession_groups> categorizes accession types for use in HTML select
boxes.

The resulting groups have the following structure:

 {
  group_label => $label, types => [{}],
 }
 e.g.
 {
  group_label => 'Uniprot',
  types => [
    {name => 'uniprot_id', ...},
    {name => 'uniprot_acc', ...},
  ],
 }

The C<types> key contains a list of accessions in the group as fetched
from the C<L</accessions>> attribute.

=cut

has accession_groups => (is => 'lazy', isa => ArrayRef,);
sub _build_accession_groups {
    my ($self) = @_;

    my @acc_groups = (
        # group_name [accessions]
        ['NCBI',         [qw(entrez_gene_id entrez_gene_symbol entrez_refseq_id entrez_protein_id entrez_unigene_id pubmed_id)],],
        ['Uniprot',      [qw(uniprot_acc uniprot_id)], ],
        ['CritterBases', [qw(flybase_id wormbase_id)],],
#        [],
    );

    my @return = map {{
        group_label => $_->[0], types => [map {$self->accessions->{$_}} @{$_->[1]}],
    }} @acc_groups;

    return \@return;
}


1;
__END__
