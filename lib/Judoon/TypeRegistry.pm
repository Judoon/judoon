package Judoon::TypeRegistry;

use Moo;
use MooX::Types::MooseLike::Base qw(InstanceOf);

use Type::Registry;


has registry => (
    is      => 'lazy',
    isa     => InstanceOf['Type::Registry'],
    handles => [qw(simple_lookup)],
);
sub _build_registry {
    my ($self) = @_;
    my $reg = Type::Registry->for_me;
    $reg->add_types("Judoon::Types::Core");
    $reg->add_types("Judoon::Types::Biology::Accession");
    return $reg;
}


sub all_types {
    my ($self) = @_;
    return sort keys %{ $self->registry };
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
