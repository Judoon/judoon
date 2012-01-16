package Judoon::Web::Controller::Root;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller::ActionRole' }


use Data::Printer;

#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#
__PACKAGE__->config(namespace => '');

=head1 NAME

Judoon::Web::Controller::Root - Root Controller for Judoon::Web

=head1 DESCRIPTION

[enter your description here]

=head1 METHODS

=head2 index

The root page (/)

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    $c->stash->{template} = 'index.tt2';
}

=head2 default

Standard 404 error page

=cut

sub default :Path {
    my ( $self, $c ) = @_;
    $c->response->body( 'Page not found' );
    $c->response->status(404);
}


sub base : Chained('') PathPart('') CaptureArgs(0) {}




sub edit : Chained('/login/required') PathPart('') CaptureArgs(0) {}


sub user_base    : Chained('edit')      PathPart('user') CaptureArgs(0) {}
sub user_addlist : Chained('user_base') PathPart('')     Args(0) {
    my ($self, $c) = @_;
    $c->res->redirect($c->uri_for_action('user_view', [$c->user->id]));
}
sub user_id : Chained('user_base') PathPart('') CaptureArgs(1) {
    my ($self, $c, $user_login) = @_;
    $c->stash->{user_login} = $user_login;
    $c->stash->{user}       = $c->model('Users')->get_user($user_login);
}
sub user_view : Chained('user_id') PathPart('') Args(0) {
    my ($self, $c) = @_;
    $c->stash->{datasets} = $c->model('Users')->get_datasets($c->stash->{user_login});
    $c->stash->{template} = 'user_view.tt2';
}


sub dataset_base : Chained('user_id') PathPart('dataset') CaptureArgs(0) {}
sub dataset_addlist : Chained('dataset_base') PathPart('') Args(0) {
    my ($self, $c) = @_;

    my $model      = $c->model('Users');
    my $user_login = $c->stash->{user_login};

    if (my $upload = $c->req->upload('dataset')) {
        my $dataset_id = $model->import_data_for_user($user_login, $upload->fh);
        $c->res->redirect($c->uri_for_action(
            'dataset_view', [$user_login, $dataset_id]
        ));
        $c->detach();
    }

    $c->stash->{datasets} = $model->get_datasets($user_login);
    $c->stash->{template} = 'dataset_list.tt2';
}
sub dataset_id : Chained('dataset_base') PathPart('') CaptureArgs(1) {
    my ($self, $c, $dataset_id) = @_;
    my $dataset             = $c->model('Users')->get_dataset($dataset_id);
    $c->stash->{dataset}    = $dataset;
    my $ds_data             = $dataset->{data};
    $c->stash->{ds_headers} = shift @$ds_data;
    $c->stash->{ds_rows}    = $ds_data;
}
sub dataset_view : Chained('dataset_id') PathPart('') Args(0) {
    my ($self, $c) = @_;

    my $params = $c->req->params;
    if ($params->{'dataset.name'}) {
        my $ds = $c->stash->{dataset};
        $c->stash->{dataset} = $c->model('Users')->update_dataset(
            $ds->{id}, {name => $params->{'dataset.name'}},
        );
    }
    $c->stash->{template}   = 'dataset_view.tt2';
}


# /dataset/$id/column
sub column_base : Chained('dataset_id')  PathPart('column') CaptureArgs(0) { }
sub column_addlist : Chained('column_base') PathPart('')       Args(0)        {
    my ($self, $c) = @_;

    my $columns = [map {{header => $_}} @{$c->stash->{ds_headers}}];
    my $rows    = $c->stash->{ds_rows};
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

    $c->stash->{columns}  = $columns;
    $c->stash->{template} = 'column_list.tt2';
}
sub column_id   : Chained('column_base') PathPart('')       CaptureArgs(1) { }
sub column_view : Chained('column_id')   PathPart('')       Args(0)        { }


# Pages
sub page_base : Chained('dataset_id') PathPart('page') CaptureArgs(0) {}
sub page_addlist : Chained('page_base') PathPart('') Args(0) {
    my ($self, $c) = @_;
    $c->stash->{template} = 'page_list.tt2';
}
sub page_id : Chained('page_base') PathPart('') CaptureArgs(1) {
    my ($self, $c, $page_id) = @_;
    $c->stash->{page_id} = $page_id;
}
sub page_view : Chained('page_id') PathPart('') Args(0) {
    my ($self, $c) = @_;
    $c->stash->{template} = 'page_view.tt2';
}




# Public pages
sub public_page_base : Chained('base') PathPart('page') CaptureArgs(0) {}
sub public_page_addlist : Chained('public_page_base') PathPart('') Args(0) {
    my ($self, $c) = @_;
    $c->stash->{template} = 'public_page_list.tt2';
}
sub public_page_id : Chained('public_page_base') PathPart('') CaptureArgs(1) {
    my ($self, $c, $page_id) = @_;
    $c->stash->{page_id} = $page_id;
}
sub public_page_view : Chained('public_page_id') PathPart('') Args(0) {
    my ($self, $c) = @_;
    $c->stash->{template} = 'public_page_view.tt2';
}




=head2 end

Attempt to render a view, if needed.

=cut

sub end : ActionClass('RenderView') {}

=head1 AUTHOR

Fitz Elliott

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
