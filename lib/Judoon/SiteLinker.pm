package Judoon::SiteLinker;

use Moo;
use MooX::Types::MooseLike::Base qw(HashRef ArrayRef);

use List::AllUtils qw(zip);

=pod

=encoding utf8

=head1 NAME

Judoon::SiteLinker - Utility class for mapping accessions to websites

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut


=head2 _build_sites

sites is a hashref of website properties keyed off the website
identifier.  The properties have the following structure:

 {name => $website_id, label => $descriptive_name}

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


=head2 _build_accessions

accessions is a hashref of accession properties keyed off the
accession identifier.  The property structure is:

 {name => $acc_id, label => $descriptive_name, example => $example_accession}

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


=head2 mapping

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
