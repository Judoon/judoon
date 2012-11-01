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

=head2 update_or_create_objects

Intercept C<update_or_create_objects> to allow cloning a page from an
existing page or from a provided template.

=cut

around 'update_or_create_objects' => sub {
    my $orig = shift;
    my $self = shift;
    my $c    = shift;

    my $params = $c->req->params;
    if (grep {exists $params->{$_}} qw(page.clone_template page.clone_from)) {

        my $dataset = $c->req->get_chained_object(0)->[0];
        my $new_page;
        if (my $file = $params->{'page.clone_template'}) {
            my $fh = $c->req->upload('page.clone_template')->fh;
            my $page_template = do { local $/ = undef; <$fh>; };
            $new_page = $dataset->new_related('pages',{})
                ->clone_from_dump($page_template);
        }
        elsif (my ($page_id) = $params->{'page.clone_from'}) {
            my $existing_page = $c->user->obj->my_pages->find({id => $page_id})
                or die q{That page doesn't exist!};

            $new_page = $dataset->new_related('pages',{})
                ->clone_from_existing($existing_page);
        }

        $c->req->clear_objects();
        $c->req->add_object([$new_page, {}]);
    }
    else {
        $self->$orig($c);
    }
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
