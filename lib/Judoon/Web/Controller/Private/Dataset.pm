package Judoon::Web::Controller::Private::Dataset;

=pod

=encoding utf8

=head1 NAME

Judoon::Web::Controller::Private::Dataset - dataset actions

=head1 DESCRIPTION

The RESTish controller for managing actions on one or more datasets.

=cut

use Moose;
use namespace::autoclean;

BEGIN { extends 'Judoon::Web::ControllerBase::Private'; }
with qw(
    Judoon::Web::Controller::Role::TabularData
);

use JSON qw(encode_json);

__PACKAGE__->config(
    action => {
        base => { Chained => '/user/id', PathPart => 'dataset', },
    },
    rpc => {
        template_dir => 'dataset',
        stash_key    => 'dataset',
    },

    # DBIC result class
    class                   =>  'User::Dataset',
    # Columns required to create
    create_requires         =>  [qw/name notes original permission user_id/],
    # Additional non-required columns that create allows
    create_allows           =>  [qw//],
    # Columns that update allows
    update_allows           =>  [qw/name notes original permission user_id/],
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
        qw/id user_id name notes original nbr_rows nbr_columns tablename permission/,
        { 'ds_columns' => [qw/id dataset_id name sort data_type accession_type shortname/] },
        { 'pages'      => [qw/id dataset_id title preamble postamble permission/] },
    ],

);


# max size in bytes for an uploaded spreadsheet
my $SPREADSHEET_MAX_SIZE = 10_000_000;


=head1 METHODS

=head2 update_or_create (around)

If we get a file upload, call the C<< $user->import_data >> method to
create our dataset.

=cut

around update_or_create => sub {
    my $orig = shift;
    my $self = shift;
    my $c    = shift;

    if (my $file = $c->req->params->{'dataset.file'}) {
        my $fh = $c->req->upload('dataset.file')->fh;
        (my $extension = $file) =~ s/.*\.//;
        my $dataset = $c->user->obj->import_data($fh, $extension);
        $dataset->insert;
        $c->req->clear_objects();
        $c->req->add_object([$dataset, {}]);
    }
    else {
        $self->$orig($c);
    }
};


=head2 private_base (before)

Restrict access to owners and visitors seeing object_GET.

=cut

before private_base => sub {
    my ($self, $c) = @_;
    if (!$c->stash->{user}{is_owner} and $c->req->method ne 'GET') {
        $self->set_error(
            $c, 'You must be the owner to do this',
        );
        $self->go_here($c, '/login/login', [],);
        $c->detach;
    }
};


=head2 list_GET

Send user to their overview page.

=cut

override list_GET => sub {
    my ($self, $c) = @_;
    $self->go_here($c, '/user/edit');
};


=head2 list_POST (before) (after)

Do some sanity-checking on the uploaded file, then create a basic page
for the user after creating the dataset.

=cut

before list_POST => sub {
    my ($self, $c) = @_;
    if (not $c->req->params->{'dataset.file'}) {
        $self->set_error($c, 'No file provided');
        $self->go_here($c, '/user/edit', [$c->stash->{user}{id}]);
        $c->detach();
    }
    elsif ($c->req->upload('dataset.file')->size > $SPREADSHEET_MAX_SIZE)  {
        $self->set_error(
            $c, 'Your spreadsheet is too big. It must be less than 10 megabytes.',
        );
        $self->go_here($c, '/user/edit', [$c->stash->{user}{id}]);
        $c->detach();
    }
};

after list_POST => sub {
    my ($self, $c) = @_;
    my $dataset = $c->req->get_object(0)->[0];
    $dataset->create_basic_page();
};


=head2 object_GET (after)

If the user is not the owner, or the 'preview' view has been
requested, then show the preview (non-edit) page.  Otherwise, add the
dataset pages to the stash.  Also handle tabular data download requests.

=cut

after object_GET => sub {
    my ($self, $c) = @_;

    my $dataset = $c->req->get_object(0)->[0];

    my $view = $c->req->param('view') // '';
    if (!$c->stash->{user}{is_owner} || $view eq 'preview') {
        my @ds_columns = $dataset->ds_columns_ordered->all;
        $c->stash->{dataset_column}{list} = \@ds_columns;
        $c->stash->{column_names_json} = encode_json([map {$_->shortname} @ds_columns]);
        $c->stash->{template} = 'dataset/preview.tt2';
        $c->detach();
    }


    my $data_table = $dataset->data_table;
    my $headers = shift @$data_table;
    $self->table_view(
        $c, $view, $dataset->name,
        $headers, $data_table,
    );

    if (my (@pages) = $dataset->pages_rs->all) {
        $c->stash->{page}{list} = [
            map {{ $_->get_columns }} @pages
        ];
    }

    my @all_pages;
    for my $ds ($c->user->obj->datasets_rs->all) {
        push @all_pages, $ds->pages_rs->all;
    }
    $c->stash->{all_pages}{list} = \@all_pages;
};


=head2 object_DELETE (after)

Return to user overview instead of dataset list

=cut

after object_DELETE => sub {
    my ($self, $c) = @_;
    my @captures = @{$c->req->captures};
    pop @captures;
    $self->go_here($c, '/user/edit', \@captures);
};


__PACKAGE__->meta->make_immutable;

1;
__END__
