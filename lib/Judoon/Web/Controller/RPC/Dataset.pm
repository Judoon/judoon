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
    my $ds_data = $c->stash->{dataset}{object}->data();
    $c->stash->{dataset}{object}{headers} = shift @$ds_data;
    $c->stash->{dataset}{object}{rows}    = $ds_data;
};


=head2 edit_object

Update the dataset, setting name and notes to '' if unset.

=cut

override edit_object => sub {
    my ($self, $c, $params) = @_;
    return $c->stash->{dataset}{object}->update({
        name  => ($params->{'dataset.name'}  // ''),
        notes => ($params->{'dataset.notes'} // ''),
    });
};


=head2 object_GET (after)

Add the dataset's first page to the stash.

=cut

after object_GET => sub {
    my ($self, $c) = @_;

    if (my ($page) = $c->stash->{dataset}{object}->pages) {
        $c->stash->{dataset}{object}{has_page} = 1;
        $c->stash->{dataset}{object}{page}     = $page;
    }
};



__PACKAGE__->meta->make_immutable;

1;
__END__
