package Judoon::Transform::Accession::ViaUniprot;

use Moo;


with 'Judoon::Transform::Role::Base',
     'Judoon::Transform::Role::OneInput';

use LWP::UserAgent;

my $base = 'http://www.uniprot.org';
my $tool = 'mapping';
my $contact = 'felliott@virginia.edu';
my $agent = LWP::UserAgent->new(agent => "libwww-perl $contact");
push @{$agent->requests_redirectable}, 'POST';


my @ids = (
    # Name	Abbreviation	Direction

    # **UniProt**
    ['UniProtKB AC/ID','ACC+ID','from'],
    ['UniProtKB AC','ACC','to'],
    ['UniProtKB ID','ID','to'],
    ['UniParc','UPARC','both'],
    ['UniRef50','NF50','both'],
    ['UniRef90','NF90','both'],
    ['UniRef100','NF100','both'],

    # Other sequence databases
    ['EMBL/GenBank/DDBJ','EMBL_ID','both'],
    ['EMBL/GenBank/DDBJ CDS','EMBL','both'],
    ['PIR','PIR','both'],
    ['UniGene','UNIGENE_ID','both'],
    ['Entrez Gene (GeneID)','P_ENTREZGENEID','both'],
    ['GI number*','P_GI','both'],
    ['IPI','P_IPI','both'],
    ['RefSeq Protein','P_REFSEQ_AC','both'],
    ['RefSeq Nucleotide','REFSEQ_NT_ID','both'],

    # 3D structure databases
    ['PDB','PDB_ID','both'],
    ['DisProt','DISPROT_ID','both'],

    # Protein-protein interaction databases
    ['DIP','DIP_ID','both'],
    ['MINT','MINT_ID','both'],
    ['STRING','STRING_ID','both'],

    # Protein family/group databases
    ['Allergome','ALLERGOME_ID','both'],
    ['MEROPS','MEROPS_ID','both'],
    ['mycoCLAP','MYCOCLAP_ID','both'],
    ['PeroxiBase','PEROXIBASE_ID','both'],
    ['PptaseDB','PPTASEDB_ID','both'],
    ['REBASE','REBASE_ID','both'],
    ['TCDB','TCDB_ID','both'],

    # PTM databases
    ['PhosSite','PHOSSITE_ID','both'],

    # Polymorphism databases
    ['DMDM','DMDM_ID','both'],

    # 2D gel databases
    ['World-2DPAGE','WORLD_2DPAGE_ID','both'],

    # Protocols and materials databases
    ['DNASU','DNASU_ID','both'],

    # Genome annotation databases
    ['Ensembl','ENSEMBL_ID','both'],
    ['Ensembl Protein','ENSEMBL_PRO_ID','both'],
    ['Ensembl Transcript','ENSEMBL_TRS_ID','both'],
    ['Ensembl Genomes','ENSEMBLGENOME_ID','both'],
    ['Ensembl Genomes Protein','ENSEMBLGENOME_PRO_ID','both'],
    ['Ensembl Genomes Transcript','ENSEMBLGENOME_TRS_ID','both'],
    ['GeneID','P_ENTREZGENEID','both'],
    ['KEGG','KEGG_ID','both'],
    ['PATRIC','PATRIC_ID','both'],
    ['UCSC','UCSC_ID','both'],
    ['VectorBase','VECTORBASE_ID','both'],

    # Organism-specific gene databases
    ['ArachnoServer','ARACHNOSERVER_ID','both'],
    ['CGD','CGD','both'],
    ['ConoServer','CONOSERVER_ID','both'],
    ['CYGD','CYGD_ID','both'],
    ['dictyBase','DICTYBASE_ID','both'],
    ['EchoBASE','ECHOBASE_ID','both'],
    ['EcoGene','ECOGENE_ID','both'],
    ['euHCVdb','EUHCVDB_ID','both'],
    ['EuPathDB','EUPATHDB_ID','both'],
    ['FlyBase','FLYBASE_ID','both'],
    ['GeneCards','GENECARDS_ID','both'],
    ['GeneFarm','GENEFARM_ID','both'],
    ['GenoList','GENOLIST_ID','both'],
    ['H-InvDB','H_INVDB_ID','both'],
    ['HGNC','HGNC_ID','both'],
    ['HPA','HPA_ID','both'],
    ['LegioList','LEGIOLIST_ID','both'],
    ['Leproma','LEPROMA_ID','both'],
    ['MaizeGDB','MAIZEGDB_ID','both'],
    ['MIM','MIM_ID','both'],
    ['MGI','MGI_ID','both'],
    ['neXtProt','NEXTPROT_ID','both'],
    ['Orphanet','ORPHANET_ID','both'],
    ['PharmGKB','PHARMGKB_ID','both'],
    ['PomBase','POMBASE_ID','both'],
    ['PseudoCAP','PSEUDOCAP_ID','both'],
    ['RGD','RGD_ID','both'],
    ['SGD','SGD_ID','both'],
    ['TAIR','TAIR_ID','both'],
    ['TubercuList','TUBERCULIST_ID','both'],
    ['WormBase','WORMBASE_ID','both'],
    ['WormBase Transcript','WORMBASE_TRS_ID','both'],
    ['WormBase Protein','WORMBASE_PRO_ID','both'],
    ['Xenbase','XENBASE_ID','both'],
    ['ZFIN','ZFIN_ID','both'],

    # Phylogenomic databases
    ['eggNOG','EGGNOG_ID','both'],
    ['GeneTree','GENETREE_ID','both'],
    ['HOGENOM','HOGENOM_ID','both'],
    ['HOVERGEN','HOVERGEN_ID','both'],
    ['KO','KO_ID','both'],
    ['OMA','OMA_ID','both'],
    ['OrthoDB','ORTHODB_ID','both'],
    ['ProtClustDB','PROTCLUSTDB_ID','both'],

    # Enzyme and pathway databases
    ['BioCyc','BIOCYC_ID','both'],
    ['Reactome','REACTOME_ID','both'],
    ['UniPathWay','UNIPATHWAY_ID','both'],

    # Gene expression databases
    ['CleanEx','CLEANEX_ID','both'],
    ['GermOnline','GERMONLINE_ID','both'],

    # Other
    ['ChEMBL','CHEMBL_ID','both'],
    ['ChiTaRS','CHITARS_ID','both'],
    ['DrugBank','DRUGBANK_ID','both'],
    ['GenomeRNAi','GENOMERNAI_ID','both'],
    ['NextBio','NEXTBIO_ID','both'],

);

my %input_keys = map {$_->[0] => $_->[1]}
    grep {$_->[2] eq 'both' || $_->[2] eq 'from'} @ids;
my %output_keys = map {$_->[0] => $_->[1]}
    grep {$_->[2] eq 'both' || $_->[2] eq 'to'} @ids;


has input_format  => (is => 'ro');
has output_format => (is => 'ro', required => 1);


sub result_data_type      { return 'text'; }

sub apply_batch {
    my ($self, $col_data) = @_;

    my $params = {
        from   => $input_keys{ $self->input_format },
        to     => $output_keys{ $self->output_format },
        format => 'tab',
        query  => join(' ', @$col_data),
    };

    my $response = $agent->post("$base/$tool/", $params);
    while (my $wait = $response->header('Retry-After')) {
        print STDERR "Waiting ($wait)...\n";
        sleep $wait;
        $response = $agent->get($response->base);
    }

    return '' if (not $response->is_success);
    my $accs = $response->content;
    my @accs = split /\n/, $accs;
    shift @accs;

    my %result = map {split /\t/, $_} @accs;
    my @transformed = map {$result{$_} // ''} @$col_data;
    return \@transformed;
}


1;
__END__
