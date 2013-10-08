package Judoon::API::Resource::DatasetColumns;


use HTTP::Throwable::Factory qw(http_throw);
use Judoon::LookupRegistry;

use Moo;
use namespace::clean;

extends 'Web::Machine::Resource';
with 'Judoon::Role::JsonEncoder';
with 'Judoon::API::Resource::Role::Set';

sub allowed_methods {
    my ($self) = @_;
     return [
        qw(GET HEAD),
        ( $_[0]->writable ) ? (qw(POST)) : ()
    ];
}

sub create_resource {
    my ($self, $data) = @_;

    my $dataset = $self->set->first->dataset;
    my $owner   = $dataset->user;

    my $registry = Judoon::LookupRegistry->new({user => $owner,});
    my $full_id  = $data->{that_table_id} // '';
    my $lookup   = $registry->find_by_full_id($full_id);
    if (not $lookup) {
        http_throw(Forbidden => {
            message => "No such lookup: $full_id",
        });
    }
    elsif ($lookup->group_id eq 'internal') {
        if (!$owner->datasets_rs->find({id => $lookup->id})) {
            http_throw(Forbidden => {
                message => "You don't have permission to access the joined dataset",
            });
        }
    }

    my $new_col;
    $dataset->result_source->schema->txn_do(
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
for an internal lookup.  Load and run lookup to create new
computed column.

=cut
