package Judoon::API::Resource::DatasetColumns;

use Moo;

extends 'Web::Machine::Resource';
with 'Judoon::Role::JsonEncoder';
with 'Judoon::API::Resource::Role::Set';

use HTTP::Throwable::Factory qw(http_throw);
use Module::Load;

sub create_resource {
    my ($self, $data) = @_;

    if ($data->{module} eq 'Accession::JoinTable') {
        my $owner = $self->set->first->dataset->user;
        if (my $ds = $owner->datasets_rs->find($data->{join_dataset})) {
            $data->{join_dataset} = $ds;
        }
        else {
            http_throw(Forbidden => {
                message => "You don't have permission to access the joined dataset",
            });
        }
    }

    my $module = "Judoon::Transform::".$data->{module};
    load $module;

    my $new_col;
    $self->set->result_source->schema->txn_do(
        sub {
            $new_col = $self->set->first->dataset->new_computed_column(
                $data->{name}, $module->new( $data ),
            );
        }
    );

    return $new_col;
}


1;
__END__

=pod

=for stopwords JoinTable

=encoding utf8

=head1 NAME

Judoon::API::Resource::DatasetColumns - A set of DatasetColumns

=head1 DESCRIPTION

See L</Web::Machine::Resource>.

=head1 METHODS

=head2 create_resource

Intercept parameters to make sure user has access to the joined table
for a JoinTable transform.  Load and run transforms to create new
computed column.

=cut
