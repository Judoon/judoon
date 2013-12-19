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
        base => { Chained => '/base', PathPart => 'datasets', },
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
    $c->stash( datatable => {
        data_url    => $c->uri_for_action('/api/datasetdata/data', [$dataset->id]),
        columns_url => $c->uri_for_action('/api/wm/dscols', [$dataset->id]),
    });
    return;
}


__PACKAGE__->meta->make_immutable;
1;
__END__
