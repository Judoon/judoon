package Judoon::Web::Controller::Private::Page;

=pod

=encoding utf8

=head1 NAME

Judoon::Web::Controller::Private::Page - page actions

=head1 DESCRIPTION

The RESTish controller for managing actions on one or more pages.
Currently chains off of ::Private::Dataset, but this may be changed
later.

=cut

use Moose;
use namespace::autoclean;

BEGIN { extends 'Judoon::Web::ControllerBase::Private'; }
with qw(
    Judoon::Web::Controller::Role::TabularData
);

use FileHandle;
use Judoon::Standalone;

__PACKAGE__->config(
    action => {
        base => { Chained => '/private/dataset/chainpoint', PathPart => 'page', },
    },
    rpc => {
        template_dir => 'page',
        stash_key    => 'page',
        name         => 'page',
        name_plural  => 'pages',
    },

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

    # Every possible prefetch parameter allowed
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


=head1 METHODS

=head2 generate_rs (around)

Restrict rs to C<Pages>s for the parent C<Dataset>.

=cut

around generate_rs => sub {
    my $orig = shift;
    my $self = shift;
    my $c    = shift;
    my $rs = $self->$orig($c);
    return $rs->for_dataset($c->req->get_chained_object(-1)->[0]);
};


=head2 validate_object (before)

Default C<Page> parameters to empty strings.

=cut

before validate_object => sub {
    my ($self, $c, $obj) = @_;
    my ($object, $params) = @$obj;

    $params->{title}      //= q{};
    $params->{preamble}   //= q{};
    $params->{postamble}  //= q{};
    $params->{dataset_id} //= $c->req->get_chained_object(-1)->[0]->id;
};


=head2 update_or_create (around)

Intercept C<update_or_create_objects> to allow cloning a page from an
existing page or from a provided template.

=cut

around update_or_create => sub {
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


=head2 private_base (before)

Restrict access to owners and visitors seeing object_GET.

=cut

before private_base => sub {
    my ($self, $c) = @_;
    if (!$c->stash->{user}{is_owner} and $c->req->method ne 'GET') {
        $self->set_error($c, 'You must be the owner to do this');
        $self->go_here($c, '/login/login', [],);
        $c->detach;
    }
};


=head2 list_GET

Send user to their overview page.

=cut

override list_GET => sub {
    my ($self, $c) = @_;
    $self->go_here($c, '/user/edit', [$c->req->captures->[0]]);
};


=head2 id (after)

Every page that chains from the id actions needs a list of ds_columns
that have already been used.  Add that to the stash here.

=cut

after id => sub {
    my ($self, $c) = @_;

    my $dataset   = $c->req->get_chained_object(-1)->[0];
    my $page      = $c->req->get_object(0)->[0];
    my @page_cols = $page->page_columns_ordered->all;

    my %used;
    for my $column (@page_cols) {
        my $tmpl = $column->template;
        for my $var ($tmpl->get_variables) {
            push @{$used{$var}}, $column->title;
        }
    }

    my @headers_used = map {{
        title => $_->name, used_in => join(', ', @{$used{$_->shortname} || []}),
    }} $dataset->ds_columns_ordered->all;
    $c->stash->{dataset}{headers_used} = \@headers_used;
};


=head2 object_GET (after)

If the user is not the owner, or the 'preview' view has been
requested, then show the preview (non-edit) page.  Otherwise, add the
page columns to the stash.  Also handle tabular data download
requests, standalone application requests, and downloadable template
requests.


=cut

after object_GET => sub {
    my ($self, $c) = @_;

    my $page = $c->req->get_object(0)->[0];
    my @page_columns = $page->page_columns_ordered->all;
    $c->stash->{page_column}{list} = \@page_columns;

    my $view = $c->req->param('view') // '';
    if (!$c->stash->{user}{is_owner} || $view eq 'preview') {
        $c->stash->{page_column}{templates}
            = [map {$_->template->to_jstmpl} @page_columns];
        $c->stash->{template} = 'page/preview.tt2';
        $c->detach();
    }


    $self->table_view(
        $c, $view, $page->title,
        $page->headers, $page->data_table,
    );

    if ($view eq 'standalone') {
        my $type = $c->req->param('format') // 'zip';
        my %allowed = qw(zip 1 tgz 1);
        $type = $allowed{$type} ? $type : 'zip';

        my $standalone   = Judoon::Standalone->new({page => $page});
        my $archive_path = $standalone->compress($type);

        $c->res->headers->header( "Content-Type" => "application/$type" );
        $c->res->headers->header( "Content-Disposition" => "attachment; filename=judoon.$type" );
        my $archive_fh = FileHandle->new;
        $archive_fh->open($archive_path, 'r');
        $c->res->body($archive_fh);
        $c->detach();
    }
    elsif ($view eq 'template') {
        $c->res->headers->header( "Content-Type" => "application/json" );
        my $name = $page->title;
        $c->res->headers->header( "Content-Disposition" => "attachment; filename=$name.json" );
        $c->res->body($page->dump_to_user);
        $c->detach();
    }
};


=head2 object_DELETE (after)

return to user overview instead of page list

=cut

after object_DELETE => sub {
    my ($self, $c) = @_;
    my @captures = @{$c->req->captures};
    pop @captures; pop @captures;
    $self->go_here($c, '/user/edit', \@captures);
};


__PACKAGE__->meta->make_immutable;

1;
__END__
