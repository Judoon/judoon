package Judoon::Web::Controller::RPC::Dataset;

use Moose;
use namespace::autoclean;

BEGIN { extends 'Judoon::Web::Controller::RPC'; }

use Data::Printer;

__PACKAGE__->config(
    action => {
        base => { Chained => '/user_id', PathPart => 'dataset', },
    },
    rpc => {
        template_dir => 'dataset',
        stash_key    => 'dataset',
    },
);


override get_list => sub {
    my ($self, $c) = @_;
    return [$c->stash->{user}->datasets];
};

override add_object => sub {
    my ($self, $c, $params) = @_;
    my $upload = $c->req->upload('dataset');
    return $c->stash->{user}->import_data($upload->fh);
};

override get_object => sub {
    my ($self, $c) = @_;
    return $c->stash->{user}->datasets_rs
        ->find({id => $c->stash->{dataset}{id}});
};

after private_id => sub {
    my ($self, $c) = @_;
    my $ds_data = $c->stash->{dataset}{object}->data();
    $c->stash->{dataset}{object}{headers} = shift @$ds_data;
    $c->stash->{dataset}{object}{rows}    = $ds_data;
};


sub postadd : Chained('id') PathPart('postadd') Args(0) {
    my ($self, $c) = @_;
    $c->stash->{template} = 'dataset/postadd.tt2';
}
sub postadd_do : Chained('id') PathPart('postadd_do') Args(0) {
    my ($self, $c) = @_;

    my $params     = $c->req->params;
    my $header_col = $params->{header} // 1;
    my @row_dels   = $params->{row_delete};
    my @col_dels   = $params->{col_delete};

    $c->log->debug("Header is: $header_col");
    $c->log->debug("Row deletes are: " . p(@row_dels));
    $c->log->debug("Col deletes are: " . p(@col_dels));

    $self->go_here($c, 'edit', $c->req->captures);
}



override edit_object => sub {
    my ($self, $c, $params) = @_;
    return $c->stash->{dataset}{object}->update({
        name  => ($params->{'dataset.name'}  // ''),
        notes => ($params->{'dataset.notes'} // ''),
    });
};


after private_edit => sub {
    my ($self, $c) = @_;

    if (my ($page) = $c->stash->{dataset}{object}->pages) {
        $c->stash->{dataset}{object}{has_page} = 1;
        $c->stash->{dataset}{object}{page}     = $page;
    }
};



__PACKAGE__->meta->make_immutable;

1;
__END__
