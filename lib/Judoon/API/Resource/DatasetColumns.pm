package Judoon::API::Resource::DatasetColumns;


use HTTP::Throwable::Factory qw(http_throw);
use Judoon::LookupRegistry;

use Moo;
use namespace::clean;

extends 'Judoon::API::Resource';
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

    if (not defined $data->{new_col_name}) {
        http_throw(UnprocessableEntity => {
            message => "'new_col_name' must not be undefined",
        });
    }

    my $dataset = $self->set->first->dataset;
    my $owner   = $dataset->user;

    my $registry = Judoon::LookupRegistry->new({user => $owner,});
    my $full_id  = $data->{that_table_id} // '';
    my ($lookup, $lookup_actor);
    eval {
        $lookup       = $registry->find_by_full_id($full_id);
        $lookup_actor = $lookup->build_actor( $data );
    };
    if ($@ || !$lookup ) {
        http_throw(UnprocessableEntity => {
            message => "No such lookup: $full_id",
        });
    }


    my $new_col;
    eval {
        $new_col = $dataset->result_source->schema->txn_do(
            sub {
                return $dataset->new_computed_column(
                    $data->{new_col_name}, $lookup_actor,
                );
            }
        );
    };
    if ($@ || !$new_col) {
        http_throw(UnprocessableEntity => {
            message => "Lookup failed. Check your parameters."
        });
    }

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

=head1 AUTHOR

Fitz ELLIOTT <felliott@fiskur.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by the Rector and Visitors of the
University of Virginia.

This is free software, licensed under:

 The Artistic License 2.0 (GPL Compatible)

=cut
