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

use Clone qw(clone);
use List::AllUtils qw(zip);
use MooX::Types::MooseLike::Base qw(HashRef ArrayRef);

use Moo;
use namespace::clean;


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
    use Judoon::TypeRegistry;
    my $type_registry = Judoon::TypeRegistry->new;
    return {
        map {$_->name => $_->TO_JSON} $type_registry->accessions
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
        ['cmkb',     'Biology_Accession_Entrez_GeneId',     ['http://cmckb.cellmigration.org/gene/',],            1, 0,],
        ['cmkb',     'Biology_Accession_Entrez_GeneSymbol', ['http://cmckb.cellmigration.org/search?search_type=name_acc&keyword=',], 0, 0],
        ['flybase',  'Biology_Accession_Flybase_Id',        ['http://flybase.bio.indiana.edu/.bin/fbidq.html?',], 1, 0,],
        ['gene',     'Biology_Accession_Entrez_GeneId',     ['http://www.ncbi.nlm.nih.gov/gene/',''],             1, 0,],
        ['gene',     'Biology_Accession_Entrez_GeneSymbol', ['http://www.ncbi.nlm.nih.gov/gene?term=',],      0, 0,],
        ['kegg',     'Biology_Accession_Entrez_GeneId',     ['http://www.genome.jp/dbget-bin/www_bget?hsa:',],    1, 0,],
        ['pfam',     'Biology_Accession_Uniprot_Acc',       ['http://pfam.sanger.ac.uk/protein?acc=',],           1, 0,],
        ['unigene',  'Biology_Accession_Entrez_UnigeneId',  ['http://www.ncbi.nlm.nih.gov/unigene/',],            1, 0,],
        ['uniprot',  'Biology_Accession_Uniprot_Acc',       ['http://www.uniprot.org/uniprot/',''],               1, 0,],
        ['wormbase', 'Biology_Accession_Wormbase_Id',       ['http://www.wormbase.org/db/gene/gene?class=CDS;name=',], 1, 0,],
    );

    my %mappings = (site => {}, accession => []);
    my $accession_map = clone($self->accessions);
    for my $map (@maps) {
        my ($site, $acc, $text_segs, $exact, $o2m) = @$map;
        my $link_map = {
            prefix      => $text_segs->[0],
            suffix      => $text_segs->[1] // '',
            exact       => $exact,
            one_to_many => $o2m,
        };


        push @{$accession_map->{$acc}{sites}},
            clone($self->sites->{$site});
        $accession_map->{$acc}{sites}[-1]{mapping} = $link_map;

        $mappings{site}{$site}{$acc}      = $link_map;
    }

    $mappings{accession} = [sort {$a->{name} cmp $b->{name}} values %$accession_map];

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

    my %groups;
    for my $accession (values %{$self->accessions}) {
        push @{$groups{$accession->{library}}}, $accession;
    }

    return [ map {{group_label => $_, types => $groups{$_}}} keys %groups ];
}


1;
__END__

=head1 AUTHOR

Fitz ELLIOTT <felliott@fiskur.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by the Rector and Visitors of the
University of Virginia.

This is free software, licensed under:

 The Artistic License 2.0 (GPL Compatible)

=cut
