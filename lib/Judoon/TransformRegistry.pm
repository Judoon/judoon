package Judoon::TransformRegistry;

use Moo;

my $register = {
    'lookup' => {
        id         => 'lookup',
        name       => 'Lookup',
        order      => 1,
        transforms => {
            uniprot => {
                id      => 'uniprot',
                name    => 'Via Uniprot',
                module  => 'Accession::ViaUniprot',
                accepts => 'accession',
                inputs  => [
                    'FlyBase','UniGene', 'UniProtKB AC/ID',
                ],
                outputs => [
                    'GeneId','UniProtKB ID','UniProtKB AC',
                ],
                order => 1,
            },
            # join_table => {
            #     id     => 'join_table',
            #     name   => 'Join Table',
            #     module => 'JoinTable',
            #     inputs => ['join_column', 'join_dataset'],
            #     outputs => [],
            #     order  => 2,
            # },
        },
    },
    'text' => {
        id         => 'text',
        name       => 'Text',
        order      => 2,
        transforms => {
            lowercase => {
                id     => 'lowercase',
                name   => 'LowerCase',
                module => 'String::LowerCase',
                accepts => 'text',
                order  => 1,
            },
            uppercase => {
                id     => 'uppercase',
                name   => 'UpperCase',
                module => 'String::UpperCase',
                accepts => 'text',
                order  => 2,
            },
        },
    }
};


sub type_list {
    my ($self) = @_;

    return [
        map { {id => $_->{id}, name => $_->{name}} }
        sort {$a->{order} <=> $b->{order}}
        values %$register
    ];
}

sub type {
    my ($self, $type_id) = @_;
    if (not exists $register->{$type_id}) {
        return undef;
    }

    return $register->{$type_id};
}

sub transforms_for {
    my ($self, $type_id) = @_;
    my $type = $self->type($type_id);
    return undef unless ($type);
    return [
        sort {$a->{order} <=> $b->{order}}
        values %{$type->{transforms}}
    ];
}

sub transform {
    my ($self, $type_id, $transform_id) = @_;
    my $type = $self->type($type_id);
    return undef unless ($type);
    return exists $type->{transforms}{$transform_id}
        ? $type->{transforms}{$transform_id} : undef;
}




1;
__END__
