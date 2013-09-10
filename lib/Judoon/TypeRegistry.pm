package Judoon::TypeRegistry;

use Moo;
use MooX::Types::MooseLike::Base qw(HashRef InstanceOf);

use Type::Registry;
use Safe::Isa;

has pg_types => (
    is  => 'lazy',
    isa => HashRef,
);
sub _build_pg_types {
    my ($self) = @_;

    my %pg_types;
    for my $type ($self->all_types) {
        next unless ($type->name =~ m/CoreType/);
        next unless ($type->$_can('pg_type'));
        $pg_types{$type->pg_type} = $type
    }

    return \%pg_types;
}

has registry => (
    is      => 'lazy',
    isa     => InstanceOf['Type::Registry'],
    handles => [qw(simple_lookup)],
);
sub _build_registry {
    my ($self) = @_;
    my $reg = Type::Registry->for_me;
    return $reg if (keys %$reg);

    $reg->add_types("Judoon::Types::Core");
    $reg->add_types("Judoon::Types::Biology::Accession");
    return $reg;
}


sub all_typenames {
    my ($self) = @_;
    return sort keys %{ $self->registry };
}

sub all_types {
    my ($self) = @_;
    return sort {$a->name cmp $b->name} values %{ $self->registry };
}

sub accessions {
    my ($self) = @_;
    return grep {$_->name =~ m/Accession/} $self->all_types;
}


1;
__END__

=pod

=encoding utf8

=head1 NAME

Judoon::TypeRegistry - Registry of Judoon::Types

=head1 SYNOPSIS

 use Judoon::TypeRegistry;

 my $typereg = Judoon::TypeRegistry->new;
 my $type = $typereg->simple_lookup('Biology_Accession_Entrez_GeneId');
 $type->check(1234); # ok
 $type->check("TLN1_HUMAN"); # nope

=head1 DESCRIPTION

Fetch Judoon::Types by name.

=head1 ATTRIBUTES

=head2 registry

A L</Type::Registry> object loaded with our types.

=head1 METHODS

=head2 simple_lookup

Delegated method from L</Type::Registry>

=head2 all_types

Get a list of all types stored in the registry.

=cut
