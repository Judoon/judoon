#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use Judoon::SiteLinker;

my $sitelinker = Judoon::SiteLinker->new;

is $sitelinker->sites->{wormbase}{label}, 'WormBase',
    'basic test of site records';
is $sitelinker->accessions->{pubmed_id}{label}, 'PubMed ID',
    'basic test of accession records';
is $sitelinker->mapping->{site}{cmkb}{entrez_gene_id}{prefix},
    'http://cmckb.cellmigration.org/gene/',
    'test site-to-accession records';
is_deeply $sitelinker->mapping->{site}{cmkb}{entrez_gene_id},
    $sitelinker->mapping->{accession}{entrez_gene_id}{cmkb},
    'mapping is equivalent in either direction';
my ($uniprot) = grep {$_->{group_label} eq 'Uniprot'}
    @{$sitelinker->accession_groups};
ok $uniprot, 'basic test of accession groups';
my $first_type = $uniprot->{types}[0];
is_deeply $first_type, $sitelinker->accessions->{$first_type->{name}},
    'accession groups correctly linked to accessions';

done_testing();
