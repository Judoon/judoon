package Judoon::Lookup::Role::Action::Uniprot;

use Judoon::Types::Biology::Accession qw(:all);
use Type::Utils qw(declare as union);

use Moo::Role;

with 'Judoon::Lookup::Role::WebFetch';


my $Uniprot_General = declare as union [
    Biology_Accession_Uniprot_Acc, Biology_Accession_Uniprot_Id
];

my @ids = (
    # Name	          Abbrev.	    Dir.    Type
    ['UniProtKB AC/ID',   'ACC+ID',         'from', $Uniprot_General,                   ],
    ['UniProtKB AC',      'ACC',            'to',   Biology_Accession_Uniprot_Acc,      ],
    ['UniProtKB ID',      'ID',             'to',   Biology_Accession_Uniprot_Id,       ],
    ['UniGene',           'UNIGENE_ID',     'both', Biology_Accession_Entrez_UnigeneId, ],
    ['Entrez Gene ID',    'P_ENTREZGENEID', 'both', Biology_Accession_Entrez_GeneId,    ],
    ['RefSeq Protein',    'P_REFSEQ_AC',    'both', Biology_Accession_Entrez_ProteinId, ],
    ['RefSeq Nucleotide', 'REFSEQ_NT_ID',   'both', Biology_Accession_Entrez_RefseqId,  ],
    ['FlyBase',           'FLYBASE_ID',     'both', Biology_Accession_Flybase_Id,       ],
    ['WormBase',          'WORMBASE_ID',    'both', Biology_Accession_Wormbase_Id,      ],
);

my (%input_keys, %output_keys);
for my $id (@ids) {

    my %typemap;
    @typemap{qw(name abbrev dir type)} = @$id;
    if ($typemap{dir} ne 'to') {
        $input_keys{$typemap{abbrev}} = \%typemap;
    }
    if ($typemap{dir} ne 'from') {
        $output_keys{$typemap{abbrev}} = \%typemap;
    }

}


sub result_data_type {
    my ($self) = @_;
    return $output_keys{ $self->that_selectcol_id }->{type};
}

sub lookup {
    my ($self, $col_data) = @_;

    my $params = {
        from   => $self->that_joincol_id,
        to     => $self->that_selectcol_id,
        format => 'tab',
        query  => join(' ', @$col_data),
    };

    my $response = $self->agent->post(
        'http://www.uniprot.org/mapping/', $params,
    );
    while (my $wait = $response->header('Retry-After')) {
        print STDERR "Waiting ($wait)...\n";
        sleep $wait;
        $response = $self->agent->get($response->base);
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
