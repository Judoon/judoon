package Judoon::Web::Controller::API::REST::PageColumn;

use Moose;
use namespace::autoclean;
use JSON::XS;

BEGIN { extends qw/Judoon::Web::ControllerBase::REST/; }

__PACKAGE__->config(
    # Define parent chain action and partpath
    action                  =>  { setup => { PathPart => 'page_column', Chained => '/api/rest/page/chainpoint' } },
    # DBIC result class
    class                   =>  'User::PageColumn',
    # stash namespace
    stash_namespace         => 'page_column',
    # Columns required to create
    create_requires         =>  [qw/page_id template title/],
    # Additional non-required columns that create allows
    create_allows           =>  [qw//],
    # Columns that update allows
    update_allows           =>  [qw/page_id template title sort/],
    # Columns that list returns
    list_returns            =>  [qw/id page_id title template/],

    # Every possible prefetch param allowed
    list_prefetch_allows    =>  [
        [qw/datasets/], {  'datasets' => [qw/ds_columns pages/] },
    ],

    # Order of generated list
    list_ordered_by         => [qw/id/],
    # columns that can be searched on via list
    list_search_exposes     => [
        qw/id page_id title template/,
    ],

);

around generate_rs => sub {
    my $orig = shift;
    my $self = shift;
    my $c    = shift;
    my $rs   = $self->$orig($c);
    return $rs->for_page($c->req->get_chained_object(-1)->[0])
        ->search_rs({}, {order_by => {-asc=>'sort'}});
};


before 'validate_object' => sub {
    my ($self, $c, $obj) = @_;
    my ($object, $params) = @$obj;

    if (exists $params->{template}) {
        $params->{template} //= q{[]};
    }
    $params->{page_id} //= $c->req->get_chained_object(-1)->[0]->id;
};

=head1 NAME

 - REST Controller for 

=head1 DESCRIPTION

REST Methods to access the DBIC Result Class page_columns

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
