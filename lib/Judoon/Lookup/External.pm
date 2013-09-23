package Judoon::Lookup::External;

=pod

=for stopwords

=encoding utf8

=head1 NAME

Judoon::Lookup::External - Lookup data from a non-Judoon source

=cut

use MooX::Types::MooseLike::Base qw(ArrayRef HashRef);

use Moo;

with 'Judoon::Lookup::Role::Base';

has '+dataset'     => (isa => HashRef); #InstanceOf('Judoon::Schema::Result::ExternalDataset'));
has '+group_id'    => (is => 'ro', default => 'external');
has '+group_label' => (is => 'ro', default => 'External Database');

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


sub id   { return $_[0]->dataset->{id}; }
sub name { return $_[0]->dataset->{name}; }


sub input_columns {
    my ($self) = @_;
    return [grep {$self->column_dict->{$_->{id}}->{dir} ne 'to'} @{$_[0]->columns}];
}
sub output_columns {
    my ($self) = @_;
    return [grep {$self->column_dict->{$_->{id}}->{dir} ne 'from'} @{$_[0]->columns}];
}


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


sub build_actor {
    my ($self, $args) = @_;
    return Moo::Role->create_class_with_roles(
        'Judoon::Lookup::ExternalActor',
        $self->actionroles->{ $self->id },
        'Judoon::Lookup::Role::Actor',
    )->new({
        %$args, schema => $self->schema, that_table_id => $self->id,
    });
}


1;
__END__
