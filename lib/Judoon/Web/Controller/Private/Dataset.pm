package Judoon::Web::Controller::Private::Dataset;

=pod

=encoding utf8

=head1 NAME

Judoon::Web::Controller::Private::Dataset - dataset actions

=head1 DESCRIPTION

The RESTful controller for managing actions on one or more datasets.

=cut

use Moose;
use namespace::autoclean;

BEGIN { extends 'Judoon::Web::ControllerBase::Private'; }

use JSON qw(encode_json);

__PACKAGE__->config(
    action => {
        base => { Chained => '/user/id', PathPart => 'dataset', },
    },
    rpc => {
        template_dir => 'dataset',
        stash_key    => 'dataset',
        api_path     => 'dataset',
    },
);


before private_base => sub {
    my ($self, $c) = @_;
    if (!$c->stash->{user}{is_owner} and $c->req->method ne 'GET') {
        $c->flash->{alert}{error} = 'You must be the owner to do this';
        $self->go_here($c, '/login/login', []);
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



=head1 list_POST

Create a basic page for the user after creating the dataset

=cut

after list_POST => sub {
    my ($self, $c) = @_;
    my $dataset = $c->req->get_object(0)->[0];
    $dataset->create_basic_page();
};


=head2 object_GET (after)

Add the dataset's first page to the stash.

=cut

after object_GET => sub {
    my ($self, $c) = @_;

    my $dataset = $c->req->get_object(0)->[0];

    my $view = $c->req->param('view') // '';
    if (!$c->stash->{user}{is_owner} || $view eq 'preview') {
        my @ds_columns = $dataset->ds_columns;
        $c->stash->{dataset_column}{list} = \@ds_columns;
        $c->stash->{column_names_json} = encode_json([map {$_->shortname} @ds_columns]);
        $c->stash->{template} = 'dataset/preview.tt2';
        $c->detach();
    }

    (my $name = $dataset->name) =~ s/\W/_/g;
    $name =~ s/__+/_/g;
    $name =~ s/(?:^_+|_+$)//g;

    if ($view eq 'raw') {
        $c->res->headers->header( "Content-Type" => "text/tab-separated-values" );
        $c->res->headers->header( "Content-Disposition" => "attachment; filename=$name.tab" );
        $c->stash->{plain}{data} = $dataset->as_raw;
        $c->forward('Judoon::Web::View::Download::Plain');
    }
    elsif ($view eq 'csv') {
        $c->res->headers->header( "Content-Disposition" => "attachment; filename=$name.csv" );
        $c->stash->{csv}{data} = $dataset->data_table;
        $c->forward('Judoon::Web::View::Download::CSV');
    }
    elsif ($view eq 'xls') {
        $c->res->headers->header( "Content-Type" => "application/vnd.ms-excel" );
        $c->res->headers->header( "Content-Disposition" => "attachment; filename=$name.xls" );
        $c->res->body($dataset->as_excel);
        $c->forward('Judoon::Web::View::Download::Plain');
    }

    if (my (@pages) = $dataset->pages) {
        $c->stash->{page}{list} = [
            map {{ $_->get_columns }} @pages
        ];
    }
};



=head2 object_DELETE (after)

return to user overview instead of dataset list

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
