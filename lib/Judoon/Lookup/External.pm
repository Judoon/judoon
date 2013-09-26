package Judoon::Lookup::External;

=pod

=for stopwords actionroles

=encoding utf8

=head1 NAME

Judoon::Lookup::External - Lookup data from a non-Judoon source

=cut

use MooX::Types::MooseLike::Base qw(ArrayRef HashRef);

use Moo;
with 'Judoon::Lookup::Role::Base';
use namespace::clean;


=head1 ATTRIBUTES

=head2 dataset

An hashref with the name of the requested external database.

=head2 group_id

Group identifier: C<external>

=head2 group_label

Group label: C<External Database>

=cut

has '+dataset'     => (isa => HashRef); #InstanceOf('Judoon::Schema::Result::ExternalDataset'));
has '+group_id'    => (is => 'ro', default => 'external');
has '+group_label' => (is => 'ro', default => 'External Database');


=head2 columns

A list of simple hashrefs with metadata about the columns of the
dataset.

=head2 column_dict

A hashref for looking up the properties of a column by id.

=head2 actionroles

The C<Judoon::Lookup::Role::Action::*> that should be applied to the
created actor to perform the lookup for the particular database.

=cut

my %columns_for = (
    uniprot => [
        {label => 'UniProtKB AC/ID',   id => 'ACC+ID',         dir => 'from', type => 'UniprotAcc+UniprotId',               },
        {label => 'UniProtKB AC',      id => 'ACC',            dir => 'to',   type => 'Biology_Accession_Uniprot_Acc',      },
        {label => 'UniProtKB ID',      id => 'ID',             dir => 'to',   type => 'Biology_Accession_Uniprot_Id',       },
        {label => 'UniGene',           id => 'UNIGENE_ID',     dir => 'both', type => 'Biology_Accession_Entrez_UnigeneId', },
        {label => 'Entrez Gene ID',    id => 'P_ENTREZGENEID', dir => 'both', type => 'Biology_Accession_Entrez_GeneId',    },
        {label => 'RefSeq Protein',    id => 'P_REFSEQ_AC',    dir => 'both', type => 'Biology_Accession_Entrez_ProteinId', },
        {label => 'RefSeq Nucleotide', id => 'REFSEQ_NT_ID',   dir => 'both', type => 'Biology_Accession_Entrez_RefseqId',  },
        {label => 'FlyBase',           id => 'FLYBASE_ID',     dir => 'both', type => 'Biology_Accession_Flybase_Id',       },
        {label => 'WormBase',          id => 'WORMBASE_ID',    dir => 'both', type => 'Biology_Accession_Wormbase_Id',      },
    ],
);

has columns => (is => 'lazy', isa => ArrayRef,);
sub _build_columns {
    my ($self) = @_;
    my @columns = map {{
        id    => $_->{id},
        label => $_->{label},
        type  => $_->{type},
    }} @{ $columns_for{ $self->id } }; #columns_ordered->hri;
    return \@columns;
}

has column_dict => (is => 'lazy', isa => HashRef,);
sub _build_column_dict {
    my ($self) = @_;
    return {
        map {$_->{id} => $_} @{ $columns_for{ $self->id } }
    };
}

has actionroles => (is => 'lazy', isa => HashRef,);
sub _build_actionroles {
    return {
        'uniprot' => 'Judoon::Lookup::Role::Action::Uniprot',
    };
}


=head1 METHODS

=head2 id

The id of the database.

=head2 name

The name of the database.

=cut

sub id   { return $_[0]->dataset->{id}; }
sub name { return $_[0]->dataset->{name}; }


=head2 input_columns

=head2 output_columns

For external lookups, the list of valid input columns and output
columns may not be the same.  Some databases can only translate in one
direction for a given type of accession.

=cut

sub input_columns {
    my ($self) = @_;
    return [grep {$self->column_dict->{$_->{id}}->{dir} ne 'to'} @{$_[0]->columns}];
}
sub output_columns {
    my ($self) = @_;
    return [grep {$self->column_dict->{$_->{id}}->{dir} ne 'from'} @{$_[0]->columns}];
}


=head2 input_columns_for( $output_id )

=head2 output_columns_for( $input_id )

Some output columns might be available only for certain input columns and
vice-versa.  These methods return the list of valid corresponding columns
for the given column.

=cut

sub input_columns_for {
    my ($self, $output) = @_;
    my $dir = $output->{id} =~ m/^(?:ACC|ID)$/ ? 'both' : 'from';
    return [grep {$self->column_dict->{$_->{id}}->{dir} eq $dir} @{$_[0]->columns}];
}
sub output_columns_for {
    my ($self, $input) = @_;
    my $dir = $input->{id} eq 'ACC+ID' ? 'both' : 'to';
    return [grep {$self->column_dict->{$_->{id}}->{dir} eq $dir} @{$_[0]->columns}];
}


=head2 build_actor

Builds an instance of L<Judoon::Lookup::ExternalActor> capable of
performing the requested lookup.  Applies the relevant
C<Judoon::Lookup::Role::Action::*> role.

=cut

sub build_actor {
    my ($self, $args) = @_;
    return Moo::Role->create_class_with_roles(
        'Judoon::Lookup::ExternalActor',
        $self->actionroles->{ $self->id },
        'Judoon::Lookup::Role::Actor',
    )->new($args);
}


1;
__END__
