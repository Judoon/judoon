package Judoon::Web::Controller::Private::DatasetColumn;

=pod

=encoding utf8

=head1 NAME

Judoon::Web::Controller::Private::DatasetColumn - dataset column actions

=head1 DESCRIPTION

The RESTish controller for managing actions on one or more dataset
columns.  Chains off of L</Judoon::Web::Controller::Private::Dataset>.

=cut

use Moose;
use namespace::autoclean;

BEGIN { extends 'Judoon::Web::ControllerBase::Private'; }
with qw(Judoon::Web::Controller::Role::ExtractParams);


__PACKAGE__->config(
    action => {
        base => { Chained => '/private/dataset/chainpoint', PathPart => 'column', },
    },
    rpc => {
        template_dir => 'ds_column',
        stash_key    => 'ds_column',
        name         => 'dataset column',
        name_plural  => 'dataset columns',
    },

    # DBIC result class
    class                   =>  'User::DatasetColumn',
    # Columns required to create
    create_requires         =>  [qw/dataset_id data_type name sort/],
    # Additional non-required columns that create allows
    create_allows           =>  [qw/shortname/],
    # Columns that update allows
    update_allows           =>  [qw/dataset_id data_type name sort shortname/],
    # Columns that list returns
    list_returns            =>  [qw/id dataset_id name sort data_type shortname/],

    # Every possible prefetch param allowed
    list_prefetch_allows    =>  [
        [qw/ds_columns/], { 'ds_columns' => [qw//] },
        [qw/pages/],      { 'pages' => [qw/page_columns/] },
    ],

    # Order of generated list
    list_ordered_by         => [qw/id/],
    # columns that can be searched on via list
    list_search_exposes     => [
        qw/id dataset_id name sort data_type shortname/,
    ],

);


=head1 METHODS

=head2 generate_rs (around)

Restrict rs to C<DatasetColumn>s for the parent C<Dataset>.

=cut

around generate_rs => sub {
    my $orig = shift;
    my $self = shift;
    my $c    = shift;
    my $rs = $self->$orig($c);
    return $rs->for_dataset($c->req->get_chained_object(0)->[0]);
};


=head2 private_base (before)

Restrict access to owners-only.

=cut

before private_base => sub {
    my ($self, $c) = @_;
    if (not $c->stash->{user}{is_owner}) {
        $self->set_error($c, 'You must be the owner to do this');
        $self->go_here($c, '/login/login', [],);
        $c->detach;
    }
};


=head2 list_GET (after)

Do some post-processing on the dataset data to get sample data and set
up some convenience variables.

=cut

after list_GET => sub {
    my ($self, $c) = @_;

    my $columns = $c->stash->{ds_column}{list};
    my $dataset = $c->req->get_chained_object(0)->[0];
    my $rows    = $dataset->data;
    for my $idx (0..scalar(@$columns)-1) {
        my $sample_count = 3;
        $columns->[$idx]{samples} = [];
        for my $row (@$rows) {
            last if ($sample_count <= 0);
            if (defined($row->[$idx]) && $row->[$idx] =~ m/\S/) {
                push @{$columns->[$idx]{samples}}, $row->[$idx];
                $sample_count--;
            }
        }
    }
};


=head2 list_POST (before)

C<DatasetColumn>s cannot be manually created or deleted.

=cut

before list_POST => sub {
    my ($self, $c) = @_;
    $c->response->content_type('text/plain');
    $c->response->status(405);
    $c->response->header( 'Allow' => [qw(GET PUT)] );
    $c->response->body("Method DELETE not implemented");
    $c->detach();
};


=head2 object_GET (after)

Add column metadata (data type, accession type, etc.) to stash.

=cut

after object_GET => sub {
    my ($self, $c) = @_;
    $c->stash->{accession_types} = $c->model('SiteLinker')->accession_groups;
};


=head2 object_DELETE (before)

C<DatasetColumn>s cannot be manually created or deleted.

=cut

before object_DELETE => sub {
    my ($self, $c) = @_;
    $c->response->content_type('text/plain');
    $c->response->status(405);
    $c->response->header( 'Allow' => [qw(GET PUT)] );
    $c->response->body("Method DELETE not implemented");
    $c->detach();
};


__PACKAGE__->meta->make_immutable;

1;
__END__

