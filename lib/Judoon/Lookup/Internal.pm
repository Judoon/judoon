package Judoon::Lookup::Internal;

use Judoon::Lookup::InternalActor;
use MooX::Types::MooseLike::Base qw(Str ArrayRef InstanceOf);

use Moo;

with 'Judoon::Lookup::Role::Base';
with 'Judoon::Lookup::Role::Group::Internal';


has '+dataset' => (isa => InstanceOf('Judoon::Schema::Result::Dataset'));

sub id { return $_[0]->dataset->id; }
sub name { return $_[0]->dataset->name; }

has columns => (is => 'lazy', isa => ArrayRef[],);
sub _build_columns {
    my ($self) = @_;
    my @columns = map {{
        id    => $_->{shortname},
        label => $_->{name},
        type  => $_->{data_type},
    }} $self->dataset->ds_columns_ordered->hri->all;
    return \@columns;
}
sub input_columns  { return $_[0]->columns; }
sub output_columns { return $_[0]->columns; }

sub input_columns_for  { return $_[0]->columns; }
sub output_columns_for { return $_[0]->columns; }

sub build_actor {
    my ($self, $args) = @_;
    return Judoon::Lookup::InternalActor->new({
        %$args, schema => $self->schema, that_table_id => $self->id,
    });
}


1;
__END__

=pod

=encoding utf8

=head1 NAME

Judoon::Lookup::Internal - Lookup value from another table

=head1 DESCRIPTION

Placeholder documentation

=head1 METHODS

=head2 result_data_type

C<CoreType_Text>

=head2 apply_batch

The subroutine that performs the transform.

=head2 join_column / join_dataset / to_column

=cut
