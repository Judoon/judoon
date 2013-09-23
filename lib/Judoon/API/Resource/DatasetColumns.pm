package Judoon::API::Resource::DatasetColumns;


use HTTP::Throwable::Factory qw(http_throw);
use Judoon::LookupRegistry;

use Moo;

extends 'Web::Machine::Resource';
with 'Judoon::Role::JsonEncoder';
with 'Judoon::API::Resource::Role::Set';

sub create_resource {
    my ($self, $data) = @_;

    my $dataset = $self->set->first->dataset;
    my $owner   = $dataset->user;
    my $schema  = $dataset->result_source->schema;

    # if ($data->{module} eq 'Accession::JoinTable') {
    #     my $owner = $dataset->user;
    #     if (my $ds = $owner->datasets_rs->find($data->{join_dataset})) {
    #         $data->{join_dataset} = $ds;
    #     }
    #     else {
    #         http_throw(Forbidden => {
    #             message => "You don't have permission to access the joined dataset",
    #         });
    #     }
    # }

    my $registry = Judoon::LookupRegistry->new({
        schema => $schema, user => $owner,
    });

    my $full_id = $data->{that_table_id} // '';
    my $lookup = $registry->find_by_full_id($full_id);
    if (not $lookup) {
        warn "Lookup failure! for  $full_id";
        http_throw(Forbidden => {
            message => "No such lookup: $full_id",
        });
    }

    my $new_col;
    $self->set->result_source->schema->txn_do(
        sub {
            $new_col = $dataset->new_computed_column(
                $data->{new_col_name}, $lookup->build_actor( $data ),
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
