package Judoon::Lookup::Internal;

=pod

=for stopwords

=encoding utf8

=head1 NAME

Judoon::Lookup::Internal - Lookup data from another Judoon Dataset

=cut

use Judoon::Lookup::InternalActor;
use MooX::Types::MooseLike::Base qw(ArrayRef InstanceOf);

use Moo;

with 'Judoon::Lookup::Role::Base';


has '+dataset'     => (isa => InstanceOf('Judoon::Schema::Result::Dataset'));
has '+group_id'    => (is => 'ro', default => 'internal');
has '+group_label' => (is => 'ro', default => 'My Datasets');


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


sub id { return $_[0]->dataset->id; }
sub name { return $_[0]->dataset->name; }

sub input_columns  { return $_[0]->columns; }
sub output_columns { return $_[0]->columns; }

sub input_columns_for  { return $_[0]->columns; }
sub output_columns_for { return $_[0]->columns; }

sub build_actor {
    my ($self, $args) = @_;
    my $join_dataset = $self->user->datasets_rs->find({id => $self->id});
    return Judoon::Lookup::InternalActor->new({
        %$args, join_dataset => $join_dataset,
    });
}


1;
__END__

