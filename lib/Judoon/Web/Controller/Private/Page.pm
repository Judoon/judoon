package Judoon::Web::Controller::Private::Page;

=pod

=encoding utf8

=head1 NAME

Judoon::Web::Controller::Private::Page - page actions

=head1 DESCRIPTION

The RESTful controller for managing actions on one or more pages.
Currently chains off of ::Private::Dataset, but this may be changed later.

=cut

use Moose;
use namespace::autoclean;

BEGIN { extends 'Judoon::Web::ControllerBase::Private'; }
with qw(
    Judoon::Web::Controller::Role::TabularData
);

use File::Slurp qw(slurp);
use Judoon::Standalone;

__PACKAGE__->config(
    action => {
        base => { Chained => '/private/dataset/chainpoint', PathPart => 'page', },
    },
    rpc => {
        template_dir => 'page',
        stash_key    => 'page',
        api_path     => 'page',
    },
);


before private_base => sub {
    my ($self, $c) = @_;
    if (!$c->stash->{user}{is_owner} and $c->req->method ne 'GET') {
        $self->set_error_and_redirect(
            $c, 'You must be the owner to do this', ['/login/login'],
        );
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

After L<Private/object_GET>, set up the stash parameters the page's edit
page will need.

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
        my $archive = slurp($archive_path);
        $c->res->body($archive);
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
