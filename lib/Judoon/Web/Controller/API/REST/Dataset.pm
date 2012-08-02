package Judoon::Web::Controller::API::REST::Dataset;

use Moose;
use namespace::autoclean;
use JSON::XS;

BEGIN { extends qw/Judoon::Web::ControllerBase::REST/; }

__PACKAGE__->config(
    # Define parent chain action and partpath
    action                  =>  { setup => { PathPart => 'dataset', Chained => '/api/rest/rest_base' } },
    # DBIC result class
    class                   =>  'User::Dataset',
    # stash namespace
    stash_namespace         => 'dataset',
    # Columns required to create
    create_requires         =>  [qw/data name notes original permission user_id/],
    # Additional non-required columns that create allows
    create_allows           =>  [qw//],
    # Columns that update allows
    update_allows           =>  [qw/data name notes original permission user_id/],
    # Columns that list returns
    list_returns            =>  [qw/id user_id name notes original data permission/],


    # Every possible prefetch param allowed
    list_prefetch_allows    =>  [
        [qw/ds_columns/], { 'ds_columns' => [qw//] },
        [qw/pages/],      { 'pages' => [qw/page_columns/] },
    ],

    # Order of generated list
    list_ordered_by         => [qw/id/],
    # columns that can be searched on via list
    list_search_exposes     => [
        qw/id user_id name notes original data permission/,
        { 'ds_columns' => [qw/id dataset_id name sort is_accession accession_type is_url url_root shortname/] },
        { 'pages'      => [qw/id dataset_id title preamble postamble permission/] },
    ],

);



around 'update_or_create_objects' => sub {
    my $orig = shift;
    my $self = shift;
    my $c    = shift;

    if (my $file = $c->req->params->{'dataset.file'}) {
        my $fh = $c->req->upload('dataset.file')->fh;
        (my $extension = $file) =~ s/.*\.//;
        my $dataset = $c->user->import_data($fh, $extension);
        $c->req->clear_objects();
        $c->req->add_object([$dataset, {}]);
    }
    else {
        $self->$orig($c);
    }
};


=head1 NAME

 - REST Controller for 

=head1 DESCRIPTION

REST Methods to access the DBIC Result Class datasets

=head1 AUTHOR

Fitz Elliott

=head1 SEE ALSO

L<Catalyst::Controller::DBIC::API>
L<Catalyst::Controller::DBIC::API::REST>

=head1 LICENSE



=cut

__PACKAGE__->meta->make_immutable;
1;
