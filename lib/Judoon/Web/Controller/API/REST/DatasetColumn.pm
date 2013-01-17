package Judoon::Web::Controller::API::REST::DatasetColumn;

use Moose;
use namespace::autoclean;
use JSON::XS;

BEGIN { extends qw/Judoon::Web::ControllerBase::REST/; }

__PACKAGE__->config(
    # Define parent chain action and partpath
    action                  =>  { setup => { PathPart => 'column', Chained => '/api/rest/dataset/chainpoint' } },
    # DBIC result class
    class                   =>  'User::DatasetColumn',
    # stash namespace
    stash_namespace         => 'ds_column',
    # Columns required to create
    create_requires         =>  [qw/accession_type dataset_id data_type_id is_accession name sort/],
    # Additional non-required columns that create allows
    create_allows           =>  [qw/shortname/],
    # Columns that update allows
    update_allows           =>  [qw/accession_type dataset_id data_type_id is_accession name sort shortname/],
    # Columns that list returns
    list_returns            =>  [qw/id dataset_id name sort data_type is_accession accession_type shortname/],


    # Every possible prefetch param allowed
    list_prefetch_allows    =>  [
        [qw/ds_columns/], { 'ds_columns' => [qw//] },
        [qw/pages/],      { 'pages' => [qw/page_columns/] },
    ],

    # Order of generated list
    list_ordered_by         => [qw/id/],
    # columns that can be searched on via list
    list_search_exposes     => [
        qw/id dataset_id name sort data_type is_accession accession_type shortname/,
    ],

);


around generate_rs => sub {
    my $orig = shift;
    my $self = shift;
    my $c    = shift;
    my $rs = $self->$orig($c);
    return $rs->for_dataset($c->req->get_chained_object(0)->[0]);
};


=head1 NAME

 - REST Controller for 

=head1 DESCRIPTION

REST Methods to access the DBIC Result Class dataset_columns

=head1 AUTHOR

Fitz Elliott

=head1 SEE ALSO

L<Catalyst::Controller::DBIC::API>
L<Catalyst::Controller::DBIC::API::REST>

=head1 LICENSE



=cut

__PACKAGE__->meta->make_immutable;
1;
