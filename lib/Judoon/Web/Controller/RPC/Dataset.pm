package Judoon::Web::Controller::RPC::Dataset;

=pod

=encoding utf8

=head1 NAME

Judoon::Web::Controller::RPC::Dataset - dataset actions

=head1 DESCRIPTION

The RESTful controller for managing actions on one or more datasets.

=cut

use Moose;
use namespace::autoclean;

BEGIN { extends 'Judoon::Web::Controller::RPC'; }

use Data::Printer;

__PACKAGE__->config(
    action => {
        base => { Chained => '/user/id', PathPart => 'dataset', },
    },
    rpc => {
        template_dir => 'dataset',
        stash_key    => 'dataset',
    },
);


=head2 list_GET

Send user to their overview page.

=cut

override list_GET => sub {
    my ($self, $c) = @_;
    $self->go_here($c, '/user/edit');
};


=head2 add_object

Import the dataset from the given filehandle, create a basic page,
return the dataset object.

=cut

override add_object => sub {
    my ($self, $c, $params) = @_;
    my $upload = $c->req->upload('dataset');
    my $dataset = $c->stash->{user}{object}->import_data($upload->fh);
    $dataset->create_basic_page();
    return $dataset;
};


=head2 get_object

Grab the dataset with the given id

=cut

override get_object => sub {
    my ($self, $c) = @_;
    return $c->stash->{user}{object}->datasets_rs
        ->find({id => $c->stash->{dataset}{id}});
};


=head2 private_id (after)

Unpack the dataset's headers and rows into the stash.

=cut

after private_id => sub {
    my ($self, $c) = @_;
    my $dataset = $c->stash->{dataset}{object};
    $c->stash->{dataset}{object}{headers} = [map {$_->name} $dataset->ds_columns];
    $c->stash->{dataset}{object}{rows}    = $dataset->data;
};


=head2 edit_object

Update the dataset, setting name and notes to '' if unset.

=cut

override edit_object => sub {
    my ($self, $c, $params) = @_;
    return $c->stash->{dataset}{object}->update({
        name  => ($params->{'dataset.name'}  // ''),
        notes => ($params->{'dataset.notes'} // ''),
        permission => ($params->{'dataset.permission'} // ''),
    });
};


=head2 object_GET (after)

Add the dataset's first page to the stash.

=cut

after object_GET => sub {
    my ($self, $c) = @_;

    my $dataset = $c->stash->{dataset}{object};
    (my $name = $dataset->name) =~ s/\W/_/g;
    $name =~ s/__+/_/g;
    $name =~ s/(?:^_+|_+$)//g;
    my $view = $c->req->param('view') // '';
    if ($view eq 'raw') {
        $c->res->headers->header( "Content-Type" => "text/tab-separated-values" );
        $c->res->headers->header( "Content-Disposition" => "attachment; filename=$name.tab" );
        $c->stash->{plain}{data} = $c->stash->{dataset}{object}->as_raw;
        $c->forward('Judoon::Web::View::Download::Plain');
    }
    elsif ($view eq 'csv') {
        $c->stash->{csv}{data} = $c->stash->{dataset}{object}->data_table;
        $c->res->headers->header( "Content-Disposition" => "attachment; filename=$name.csv" );
        $c->forward('Judoon::Web::View::Download::CSV');
    }
    elsif ($view eq 'xls') {
        $c->res->headers->header( "Content-Type" => "application/vnd.ms-excel" );
        $c->res->headers->header( "Content-Disposition" => "attachment; filename=$name.xls" );
        $c->res->body($c->stash->{dataset}{object}->as_excel);
        $c->forward('Judoon::Web::View::Download::Plain');
    }

    if (my ($page) = $c->stash->{dataset}{object}->pages) {
        $c->stash->{dataset}{object}{has_page} = 1;
        $c->stash->{dataset}{object}{page}     = $page;
    }
};


=head2 delete_object

delete the dataset

=cut

override delete_object => sub {
    my ($self, $c) = @_;
    $c->stash->{dataset}{object}->delete;
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
