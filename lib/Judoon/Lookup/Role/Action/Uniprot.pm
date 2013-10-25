package Judoon::Lookup::Role::Action::Uniprot;

=pod

=for stopwords

=encoding utf8

=head1 NAME

Judoon::Lookup::Role::Action::Uniprot - Lookup data via Uniprot web API

=head1 DESCRIPTION

This is our base class for internal database lookup actors.  Lookup
actors are the objects in charge of actually taking a list of data and
translating that into new data via lookups in another data
source. Objects of this class are expected to fetch their data from a
another Judoon dataset.

These objects are constructed by the C<build_actor()> method of a
L<Judoon::Lookup::Internal> object.

=cut

use Judoon::Types::Biology::Accession qw(:all);
use Type::Utils qw(declare as union);

use Moo::Role;

# for ->agent attribute
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

# maps of ids to descriptive structures
# %input_keys is currently unused
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


=head1 METHODS

=head2 validate_args

Dies unless: C<that_joincol_id> is a valid identifier for a Uniprot
Id-Mapper input B<AND> C<that_selectcol_id> is a valid identifier for
a Uniprot Id-mapper output C<AND> a mapping exists between C<that_joincol_id>
and C<that_selectcol_id>.

=cut

sub validate_args {
    my ($self) = @_;

    # Uniprot can map a Uniprot accession (ACC or ID) to any of the
    # other accession types and vice-versa.  It cannot map from a
    # non-Uniprot accession to a nother non-Uniprot accession. The
    # test for this is the direction for joincol and selectcol cannot
    # both be 'both'.
    return
        exists($input_keys{ $self->that_joincol_id })
        &&
        exists($output_keys{ $self->that_selectcol_id })
        &&
        grep {$_->{dir} ne 'both'} (
            $input_keys{ $self->that_joincol_id },
            $output_keys{ $self->that_selectcol_id },
        );
}


=head2 result_data_type

The data type of the selected output type.

=head2 lookup( \@col_data )

Build a POST request suitable for submission to the Uniprot id-mapping
web service.  For details see L<http://www.uniprot.org/faq/28>.

=cut

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
