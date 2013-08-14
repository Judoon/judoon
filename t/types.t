#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Judoon::Types::Core qw(:all);
use Judoon::Types::Biology::Accession qw(:all);
use Judoon::TypeRegistry;


subtest 'CoreType_Text' => sub {
    ok CoreType_Text->check("this is text"), 'basic pass';
    ok !CoreType_Text->check(undef), 'basic fail';
};

subtest 'CoreType_Numeric' => sub {
    ok CoreType_Numeric->check(38), 'basic pass';
    ok !CoreType_Numeric->check("moo"), 'basic fail';
};

subtest 'Biology_Accession_Entrez_GeneId' => sub {
    ok Biology_Accession_Entrez_GeneId->check(10000), 'AKT3 okay';
    ok !Biology_Accession_Entrez_GeneId->check("moo"), "'moo' isn't";

    is Biology_Accession_Entrez_GeneId->sample, '7094', 'got sample';
    is Biology_Accession_Entrez_GeneId->display_name, 'Entrez Gene ID', 'got display_name';
    is Biology_Accession_Entrez_GeneId->parent->name, 'CoreType_Text', 'got parent';
    is Biology_Accession_Entrez_GeneId->library, 'Biology::Accessions', 'got library';
};



subtest 'Registry' => sub {
    my $reg = Judoon::TypeRegistry->new;
    ok my $text_type = $reg->simple_lookup('CoreType_Text'),
        'simple lookup works';
    ok $text_type->check("moo"), ' ..and type can validate';

    ok my @keys = $reg->all_types(), 'can get list of types';
    use Data::Printer;
    p(@keys);
};

done_testing;

