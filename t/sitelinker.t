#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use Judoon::SiteLinker;

my $sitelinker = Judoon::SiteLinker->new;

is $sitelinker->sites->{wormbase}{label}, 'WormBase',
    'basic test of site records';
is $sitelinker->accessions->{Biology_Accession_Pubmed_Pmid}{label},
    'PubMed ID', 'basic test of accession records';
is $sitelinker->mapping->{site}{cmkb}{Biology_Accession_Entrez_GeneId}{prefix},
    'http://cmckb.cellmigration.org/gene/',
    'test site-to-accession records';
# is_deeply $sitelinker->mapping->{site}{cmkb}{Biology_Accession_Entrez_GeneId},
#     $sitelinker->mapping->{accession}{Biology_Accession_Entrez_GeneId}{cmkb},
#     'mapping is equivalent in either direction';
# my ($uniprot) = grep {$_->{group_label} eq 'Uniprot'}
#     @{$sitelinker->accession_groups};
# ok $uniprot, 'basic test of accession groups';
# my $first_type = $uniprot->{types}[0];
# is_deeply $first_type, $sitelinker->accessions->{$first_type->{name}},
#     'accession groups correctly linked to accessions';

done_testing();
