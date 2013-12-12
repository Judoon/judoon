package Judoon::Web::Controller::Dataset;

=pod

=encoding utf8

=head1 NAME

Judoon::Web::Controller::Dataset - display public datasets

=cut

use Moose;
use namespace::autoclean;

BEGIN { extends 'Judoon::Web::Controller'; }

with qw(
    Judoon::Web::Controller::Role::PublicDirectory
    Judoon::Role::JsonEncoder
);


__PACKAGE__->config(
    action => {
        base => { Chained => '/base', PathPart => 'dataset', },
    },

    resultset_class => 'User::Dataset',
    stash_key       => 'dataset',
    template_dir    => 'public_dataset',
);


=head1 METHODS

=head2 populate_stash

Fill in the stash with the necessary data.

=cut

sub populate_stash {
    my ($self, $c, $dataset) = @_;
    my @ds_columns = $dataset->ds_columns_ordered->hri->all;
    $c->stash->{column_json} = $self->encode_json([
        map {{name => $_->{name}, shortname => $_->{shortname}}} @ds_columns
    ]);
    return;
}


__PACKAGE__->meta->make_immutable;
1;
__END__
