package Judoon::Web::Controller::RPC::Dataset;

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


override list_GET => sub {
    my ($self, $c) = @_;
    $self->go_here($c, '/user/edit');
};

override add_object => sub {
    my ($self, $c, $params) = @_;
    my $upload = $c->req->upload('dataset');
    my $dataset = $c->stash->{user}{object}->import_data($upload->fh);
    $dataset->create_basic_page();
    return $dataset;
};

override get_object => sub {
    my ($self, $c) = @_;
    return $c->stash->{user}{object}->datasets_rs
        ->find({id => $c->stash->{dataset}{id}});
};

after private_id => sub {
    my ($self, $c) = @_;
    my $ds_data = $c->stash->{dataset}{object}->data();
    $c->stash->{dataset}{object}{headers} = shift @$ds_data;
    $c->stash->{dataset}{object}{rows}    = $ds_data;
};


override edit_object => sub {
    my ($self, $c, $params) = @_;
    return $c->stash->{dataset}{object}->update({
        name  => ($params->{'dataset.name'}  // ''),
        notes => ($params->{'dataset.notes'} // ''),
    });
};

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
