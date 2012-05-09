package Judoon::SiteLinker;

use Moose;
use namespace::autoclean;

use List::AllUtils qw(zip);

has sites      => (is => 'ro', isa => 'HashRef', lazy_build => 1);
has accessions => (is => 'ro', isa => 'HashRef', lazy_build => 1);

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


has mapping => (is => 'ro', isa => 'HashRef', lazy_build => 1);
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

has accession_groups => (is => 'ro', isa => 'HashRef', lazy_build => 1);
sub _build_accession_groups {
    my ($self) = @_;

    my @acc_groups = (
        # group_name [accessions]
        ['NCBI',         [qw(entrez_gene_id entrez_gene_symbol entrez_refseq_id entrez_protein_id entrez_unigene_id pubmed_id unigene_id)],],
        ['Uniprot',      [qw(uniprot_acc uniprot_id)], ],
        ['CritterBases', [qw(flybase_id wormbase_id)],],
#        [],
    );

}

__PACKAGE__->meta->make_immutable;

1;
__END__
