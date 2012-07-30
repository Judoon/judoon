package Judoon::Web::Controller::API::REST::Page;

use Moose;
use namespace::autoclean;
use JSON::XS;

BEGIN { extends qw/Judoon::Web::ControllerBase::REST/; }

__PACKAGE__->config(
    # Define parent chain action and partpath
    action                  =>  { setup => { PathPart => 'pages', Chained => '/api/rest/rest_base' } },
    # DBIC result class
    class                   =>  'User::Page',
    # Columns required to create
    create_requires         =>  [qw/dataset_id permission postamble preamble title/],
    # Additional non-required columns that create allows
    create_allows           =>  [qw//],
    # Columns that update allows
    update_allows           =>  [qw/dataset_id permission postamble preamble title/],
    # Columns that list returns
    list_returns            =>  [qw/id dataset_id title preamble postamble permission/],


    # Every possible prefetch param allowed
    list_prefetch_allows    =>  [
        [qw/page_columns/], {  'page_columns' => [qw//] },
		
    ],

    # Order of generated list
    list_ordered_by         => [qw/id/],
    # columns that can be searched on via list
    list_search_exposes     => [
        qw/id dataset_id title preamble postamble permission/,
        { 'page_columns' => [qw/id page_id title template/] },
		
    ],);

=head1 NAME

 - REST Controller for 

=head1 DESCRIPTION

REST Methods to access the DBIC Result Class pages

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
