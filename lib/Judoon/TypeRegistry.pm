package Judoon::TypeRegistry;

use MooX::Types::MooseLike::Base qw(HashRef InstanceOf);
use Safe::Isa;
use Type::Registry;

use Moo;
use namespace::clean;


has pg_to_judoon => (
    is  => 'lazy',
    isa => HashRef,
);
sub _build_pg_to_judoon {
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

Fetch L<Judoon::Type>s by name.

=head1 ATTRIBUTES

=head2 registry

A L</Type::Registry> object loaded with our types.

=head2 pg_to_judoon

A hashref that maps PostgreSQL data types to the closest Judoon core
type.

=head1 METHODS

=head2 simple_lookup

Delegated method from L</Type::Registry>.

=head2 all_types

Get a list of all type objects stored in the registry.

=head2 all_typenames

Get a list of all type names stored in the registry.

=head2 accessions

Get a list of all type objects that are accessions.

=head1 AUTHOR

Fitz ELLIOTT <felliott@fiskur.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by the Rector and Visitors of the
University of Virginia.

This is free software, licensed under:

 The Artistic License 2.0 (GPL Compatible)

=cut
