package Judoon::Web::Controller::API::REST::Page;

use Moose;
use namespace::autoclean;
use JSON::XS;

BEGIN { extends qw/Judoon::Web::ControllerBase::REST/; }

__PACKAGE__->config(
    # Define parent chain action and partpath
    action                  =>  { setup => { PathPart => 'page', Chained => '/api/rest/dataset/chainpoint' } },
    # DBIC result class
    class                   =>  'User::Page',
    # stash namespace
    stash_namespace         => 'page',
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
    ],

);


around generate_rs => sub {
    my $orig = shift;
    my $self = shift;
    my $c    = shift;
    my $rs = $self->$orig($c);
    return $rs->for_dataset($c->req->get_chained_object(-1)->[0]);
};


before 'validate_object' => sub {
    my ($self, $c, $obj) = @_;
    my ($object, $params) = @$obj;

    $params->{title}      //= q{};
    $params->{preamble}   //= q{};
    $params->{postamble}  //= q{};
    $params->{dataset_id} //= $c->req->get_chained_object(-1)->[0]->id;
};

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
