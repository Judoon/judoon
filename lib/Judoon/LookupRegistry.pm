package Judoon::LookupRegistry;

use MooX::Types::MooseLike::Base qw(ArrayRef HashRef InstanceOf);

use Moo;

use Judoon::Lookup::Internal;
use Judoon::Lookup::External;

has schema => (
    is       => 'ro',
    isa      => InstanceOf['Judoon::Schema'],
    required => 1,
);

has user => (
    is       => 'ro',
    isa      => InstanceOf['Judoon::Schema::Result::User'],
    required => 1,
);



has external_db => (is => 'lazy', isa => ArrayRef,);
sub _build_external_db {
    return [
        {id => 'uniprot', name => 'Uniprot',},
    ];
}


sub all_lookups {
    my ($self) = @_;
    my @all = ($self->internals(), $self->externals());
    return @all;
}
sub internals {
    my ($self) = @_;
    return map {$self->new_internal_from_obj($_)}
        $self->user->datasets_rs->all;
}

sub externals {
    my ($self) = @_;
    return map {$self->new_external_from_obj($_)}
          @{ $self->external_db };
    #     $schema->resultset('ExternalDataset')->all;
}




sub new_internal_from_obj {
    my ($self, $dataset) = @_;
    return $self->new_internal({
        dataset    => $dataset,
        that_table => $dataset->id
    });
}
sub new_internal_from_id {
    my ($self, $id) = @_;
    my $dataset = $self->schema->resultset('Dataset')->find({id => $id});
    return $self->new_internal({
        dataset    => $dataset,
        that_table => $id,
    });
}
sub new_internal {
    my ($self, $attrs) = @_;
    return Judoon::Lookup::Internal->new({schema => $self->schema, %$attrs});
}



sub new_external_from_obj {
    my ($self, $dataset) = @_;
    return $self->new_external({
        dataset    => $dataset,
        that_table => $dataset->{id},
    });
}
sub new_external_from_id {
    my ($self, $id) = @_;
    # my $dataset = $self->schema->resultset('ExternalDataset')
    #     ->find({id => $id});
    my $dataset;
    for my $ds (@{$self->external_db}) {
        if ($ds->{id} eq $id) {
            $dataset = $ds;
            last;
        }
    }
    return $self->new_external({
        dataset    => $dataset,
        that_table => $id,
    });
}
sub new_external {
    my ($self, $attrs) = @_;
    return Judoon::Lookup::External->new({schema => $self->schema, %$attrs});
}



sub find_by_type_and_id {
    my ($self, $type, $id) = @_;
    return $type eq 'internal' ? $self->new_internal_from_id($id)
         : $type eq 'external' ? $self->new_external_from_id($id)
         :                       undef;
}

sub find_by_full_id {
    my ($self, $full_id) = @_;
    return $self->find_by_type_and_id(split /_/, $full_id);
}


1;
__END__
