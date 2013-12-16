package Judoon::Web::Controller::Page;

=pod

=encoding utf8

=head1 NAME

Judoon::Web::Controller::Page - display public pages

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
        base => { Chained => '/base', PathPart => 'page', },
    },

    resultset_class => 'User::Page',
    stash_key       => 'page',
    template_dir    => 'public_page',
);



=head1 METHODS

=head2 populate_stash

Fill in the stash with the necessary data.

=cut

sub populate_stash {
    my ($self, $c, $page) = @_;
    $c->stash( datatable => {
        data_url    => $c->uri_for_action('/api/datasetdata/data', [$page->dataset_id]),
        columns_url => $c->uri_for_action('/api/wm/pagecols', [$page->id]),
    });
    return;
}


__PACKAGE__->meta->make_immutable;
1;
__END__
