package Judoon::Web::Controller::RPC::PageColumn;

use Moose;
use namespace::autoclean;

BEGIN { extends 'Judoon::Web::Controller::RPC'; }

use Judoon::Tmpl::Translator;

__PACKAGE__->config(
    action => {
        base => { Chained => '/rpc/page/id', PathPart => 'column', },
    },
    rpc => {
        template_dir => 'page_column',
        stash_key    => 'page_column',
    },
);

has translator => (is => 'ro', isa => 'Judoon::Tmpl::Translator', lazy_build => 1,);
sub _build_translator { return Judoon::Tmpl::Translator->new; }


override add_object => sub {
    my ($self, $c, $params) = @_;
    my %valid = map {my $o = $_; s/^page_column\.//; $_ => ($params->{$o} // '')}
        grep {m/^page_column\./} keys %$params;
    $valid{template} = q{};
    return $c->stash->{page}{object}->create_related('page_columns', \%valid);
};

override get_object => sub {
    my ($self, $c) = @_;
    return $c->stash->{page}{object}->page_columns_rs
        ->find({id => $c->stash->{page_column}{id}});
};

after private_edit => sub {
    my ($self, $c) = @_;

    my @ds_columns = $c->stash->{dataset}{object}->ds_columns;
    $c->stash->{ds_column}{list} = \@ds_columns;
    $c->stash->{linksets}        = \@ds_columns;

    use JSON qw(encode_json);
    $c->stash->{link_site_json} = encode_json(
        $c->stash->{ds_column}{list}[0]->get_linksites()
    );
    $c->stash->{ds_column_json} = encode_json(
        [map {{name => $_->name, shortname => $_->shortname}} @ds_columns]
    );

    if (my $template = $c->stash->{page_column}{object}->template) {
        $c->log->debug("Template is: $template");
        $c->stash->{page_column}{object}->{webwidgets}
            = $self->translator->translate(
                from => 'Native', to => 'WebWidgets',
                template => $template,
            );
    }
};

override edit_object => sub {
    my ($self, $c, $params) = @_;
    use Data::Printer;
    $c->log->debug('Params are: ' . p($params));
    return $c->stash->{page_column}{object}->update($params);
};

override munge_edit_params => sub {
    my ($self, $c) = @_;

    my $params        = $c->req->params;
    my $template_html = $params->{'page_column.template'};
    my $template      = $self->translator->translate(
        from => 'WebWidgets', to => 'Native', template => $template_html,
    );
    $params->{'page_column.template'} = $template;

    my %valid = map {my $o = $_; s/page_column\.//; $_ => $params->{$o}}
        keys %$params;
    return \%valid;;
};

override delete_object => sub {
    my ($self, $c) = @_;
    $c->stash->{page_column}{object}->delete;
};

after delete_do => sub {
    my ($self, $c) = @_;
    $c->res->redirect($c->uri_for_action('/rpc/page/edit', [@{$c->req->captures}[0,-2]]));
};

__PACKAGE__->meta->make_immutable;

1;
__END__
