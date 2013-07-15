package Judoon::API::Resource::DatasetColumns;

use Moo;

extends 'Web::Machine::Resource';
with 'Judoon::Role::JsonEncoder';
with 'Judoon::API::Resource::Role::Set';

use Module::Load;

sub create_resource {
    my ($self, $data) = @_;

    my $module = "Judoon::Transform::".$data->{module};
    load $module;

    my $new_col;
    $self->set->result_source->schema->txn_do(
        sub {
            $new_col = $self->set->first->dataset->new_computed_column(
                {name => $data->{name}},
                $module->new( $data ),
            );
        }
    );

    return $new_col;
}


1;
__END__

=pod

=encoding utf8

=head1 NAME

Judoon::API::Resource::DatasetColumns - A set of DatasetColumns

=head1 DESCRIPTION

See L</Web::Machine::Resource>.

=cut
