package Judoon::Web::Controller::API::REST::DatasetColumn;

use Moose;
use namespace::autoclean;
use JSON::XS;

BEGIN { extends qw/Judoon::Web::ControllerBase::REST/; }

__PACKAGE__->config(
    # Define parent chain action and partpath
    action                  =>  { setup => { PathPart => 'dataset_columns', Chained => '/api/rest/rest_base' } },
    # DBIC result class
    class                   =>  'User::DatasetColumn',
    # Columns required to create
    create_requires         =>  [qw/accession_type dataset_id is_accession is_url name sort url_root/],
    # Additional non-required columns that create allows
    create_allows           =>  [qw/shortname/],
    # Columns that update allows
    update_allows           =>  [qw/accession_type dataset_id is_accession is_url name sort url_root shortname/],
    # Columns that list returns
    list_returns            =>  [qw/id dataset_id name sort is_accession accession_type is_url url_root shortname/],


    # Every possible prefetch param allowed
    list_prefetch_allows    =>  [
        [qw/ds_columns/], {  'ds_columns' => [qw//] },
		[qw/pages/], {  'pages' => [qw/page_columns/] },
		
    ],

    # Order of generated list
    list_ordered_by         => [qw/id/],
    # columns that can be searched on via list
    list_search_exposes     => [
        qw/id dataset_id name sort is_accession accession_type is_url url_root shortname/,
        
    ],);

=head1 NAME

 - REST Controller for 

=head1 DESCRIPTION

REST Methods to access the DBIC Result Class dataset_columns

=head1 AUTHOR

Fitz Elliott

=head1 SEE ALSO

L<Catalyst::Controller::DBIC::API>
L<Catalyst::Controller::DBIC::API::REST>
L<Catalyst::Controller::DBIC::API::RPC>

=head1 LICENSE



=cut

__PACKAGE__->meta->make_immutable;
1;
