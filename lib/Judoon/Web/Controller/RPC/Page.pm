package Judoon::Web::Controller::RPC::Page;

use Moose;
use namespace::autoclean;

BEGIN { extends 'Judoon::Web::Controller::RPC'; }

__PACKAGE__->config(
    action => {
        base => { Chained => '/rpc/dataset/id', PathPart => 'page', },
    },
    rpc => {
        template_dir => 'page',
        stash_key    => 'page',
    },
);


override add_object => sub {
    my ($self, $c, $params) = @_;
    return $c->model('Users')->new_page($c->stash->{dataset}{id}, $params);
};

override get_object => sub {
    my ($self, $c) = @_;
    return $c->model('Users')->get_page($c->stash->{page}{id});
};

override edit_object => sub {
    my ($self, $c, $params) = @_;
    $c->model('Users')->update_page($c->stash->{page}{id}, $params);
};

after 'private_view' => sub {
    my ($self, $c) = @_;
    $c->stash->{page_columns} = $c->model('Users')
        ->get_page_columns($c->stash->{page}{id});
};

__PACKAGE__->meta->make_immutable;

1;
__END__
