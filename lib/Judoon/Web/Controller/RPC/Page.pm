package Judoon::Web::Controller::RPC::Page;

use Moose;
use namespace::autoclean;

BEGIN { extends 'Judoon::Web::Controller::RPC'; }

use Data::Printer;

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
    return $c->stash->{dataset}{object}->create_related('pages', {
        title => '', preamble => '', postamble => '',
    });
};

override get_object => sub {
    my ($self, $c) = @_;
    return $c->stash->{dataset}{object}->pages_rs->find({id => $c->stash->{page}{id}});
};

override edit_object => sub {
    my ($self, $c, $params) = @_;
    my %valid = map {my $o = $_; s/^page\.//; $_ => ($params->{$o} // '')}
        grep {m/^page\./} keys %$params;
    return $c->stash->{page}{object}->update(\%valid);
};

after private_edit => sub {
    my ($self, $c) = @_;
    $c->stash->{page_columns} = [$c->stash->{page}{object}->page_columns];

    my %used;
    for my $page_col (@{$c->stash->{page_columns}}) {
        for my $node (map {$_->decompose} $page_col->template_to_objects()) {
            next unless ($node->type eq 'variable');
            push @{$used{$node->name}}, $page_col->title;
        }
    }
    my @headers_used = map {{
        title => $_->name, used_in => join(', ', @{$used{$_->shortname} || []}),
    }} $c->stash->{dataset}{object}->ds_columns;
    $c->stash->{dataset}{headers_used} = \@headers_used;
};


sub preview : Chained('id') PathPart('preview') Args(0) {
    my ($self, $c) = @_;

    my $page_columns = [$c->stash->{page}{object}->page_columns];
    $c->stash->{page_column}{list} = $page_columns;
    $c->stash->{page_column}{templates}
        = [map {$_->template_to_jquery} @$page_columns];
    $c->stash->{template} = 'page/preview.tt2';
}


__PACKAGE__->meta->make_immutable;

1;
__END__
