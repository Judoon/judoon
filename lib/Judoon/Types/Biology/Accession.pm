package Judoon::Types::Biology::Accession;

use strict;
use warnings;

use Type::Library
    -base,
    -declare => qw(
        Biology_Accession_Entrez_GeneId
        Biology_Accession_Entrez_GeneSymbol
        Biology_Accession_Entrez_RefseqId
        Biology_Accession_Entrez_ProteinId
        Biology_Accession_Entrez_UnigeneId
        Biology_Accession_Pubmed_Pmid
        Biology_Accession_Uniprot_Acc
        Biology_Accession_Uniprot_Id
        Biology_Accession_Flybase_Id
        Biology_Accession_Wormbase_Id
        Biology_Accession_Cmkb_OrthologAcc
        Biology_Accession_Cmkb_FamilyAcc
        Biology_Accession_Cmkb_ComplexAcc
    );

use Judoon::Type;
use Judoon::Types::Core qw(CoreType_Text);


my @types = (
    # type                constraint      sample            display_name              other
    ['Entrez_GeneId',     qr/^\d+$/,      '7094',           'Entrez Gene ID',         ['pg_type' => 'int'] ],
    ['Entrez_GeneSymbol', qr/^\w+$/,      'TLN1',           'Entrez Gene Symbol',      ],
    ['Entrez_RefseqId',   qr/^NM_\d+$/,   'NM_006289',      'RefSeq ID',               ],
    ['Entrez_ProteinId',  qr/^NP_\d+$/,   'NP_006280',      'Entrez Protein ID',       ],
    ['Entrez_UnigeneId',  qr/^\d+$/,      '686173',         'Entrez Unigene ID',       ],
    ['Pubmed_Pmid',       qr/^\d+$/,      '22270917',       'PubMed ID',               ],
    ['Uniprot_Acc',       qr/^\w+$/,      'Q9Y490',         'Uniprot ACC',             ],
    ['Uniprot_Id',        qr/^\w+_\w+$/,  'TLN1_HUMAN',     'Uniprot ID',              ],
    ['Flybase_Id',        qr/^FBgn\d+$/,  'FBgn0041789',    'FlyBase ID',              ],
    ['Wormbase_Id',       qr/^\d+$/,      'WBGene00016197', 'WormBase ID',             ],
    ['Cmkb_OrthologAcc',  qr/^co\d{8}+$/, 'co00001234',     'CMKB Ortholog Accession', ],
    ['Cmkb_FamilyAcc',    qr/^cf\d{8}+$/, 'cf00001234',     'CMKB Family Accession',   ],
    ['Cmkb_ComplexAcc',   qr/^cc\d{8}+$/, 'cc00001234',     'CMKB Complex Accession',   ],
);


for my $type (@types) {
    __PACKAGE__->meta->add_type(
        Judoon::Type->new(
            name         => 'Biology_Accession_' . $type->[0],
            display_name => $type->[3],
            parent       => CoreType_Text,
            constraint   => sub { $_ =~ $type->[1] },
            sample       => $type->[2],
            library      => 'Biology::Accessions',
            @{ $type->[4] || [] }
        )
    );
}

1;
__END__

=pod

=encoding utf8

=head1 NAME

Judoon::Types::Biology::Accession - Judoon::Types for Biology-related identifiers

=head1 SYNOPSIS

 use Judoon::Types::Biology::Accession qw(:all);

 Biology_Accession_Entrez_GeneId->check(1234);         # ok
 Biology_Accession_Entrez_GeneId->check("TLN1_HUMAN"); # not ok

=head1 DESCRIPTION

Data types for biological database identifiers.

=head1 Types

See code.

=head1 AUTHOR

Fitz ELLIOTT <felliott@fiskur.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by the Rector and Visitors of the
University of Virginia.

This is free software, licensed under:

 The Artistic License 2.0 (GPL Compatible)

=cut
