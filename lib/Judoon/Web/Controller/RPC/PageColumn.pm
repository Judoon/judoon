package Judoon::Web::Controller::RPC::PageColumn;

use Moose;
use namespace::autoclean;

BEGIN { extends 'Judoon::Web::Controller::RPC'; }

use Judoon::Template::Translator;

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

after private_edit => sub {
    my ($self, $c) = @_;
    my $translator = Judoon::Template::Translator->new();
    $c->stash->{page_column}{object}{template} =
        $translator->to_widgets($c->stash->{page_column}{object}{template});
};

override edit_object => sub {
    my ($self, $c, $params) = @_;
    use Data::Printer;
    $c->log->debug('Params are: ' . p($params));
    return $c->model('Users')
        ->update_page_column($c->stash->{page_column}{id}, $params);
};

override munge_edit_params => sub {
    my ($self, $c) = @_;

    my $params        = $c->req->params;
    my $template_html = $params->{'page_column.template'};
    my $trans         = Judoon::Template::Translator->new();

    my $template      = $trans->translate($template_html);
    $params->{'page_column.template'} = $template;
    return $params;
};


__PACKAGE__->meta->make_immutable;

1;
__END__
