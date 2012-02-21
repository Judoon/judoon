package Judoon::Web::Controller::RPC::PageColumn;

use Moose;
use namespace::autoclean;

BEGIN { extends 'Judoon::Web::Controller::RPC'; }

__PACKAGE__->config(
    action => {
        base => { Chained => '/rpc/page/id', PathPart => 'column', },
    },
    rpc => {
        template_dir => 'page_column',
        stash_key    => 'page_column',
    },
);


override add_object => sub {
    my ($self, $c, $params) = @_;
    return $c->model('Users')->add_page_column($c->stash->{page}{id}, $params);
};

override get_object => sub {
    my ($self, $c) = @_;
    return $c->model('Users')->get_page_column($c->stash->{page_column}{id});
};

override edit_object => sub {
    my ($self, $c, $params) = @_;
    return $c->model('Users')
        ->update_page_column($c->stash->{page_column}{id}, $params);
};



__PACKAGE__->meta->make_immutable;

1;
__END__
