package Judoon::Web::Controller::RPC::Page;

=pod

=encoding utf8

=head1 NAME

Judoon::Web::Controller::RPC::Page - page actions

=head1 DESCRIPTION

The RESTful controller for managing actions on one or more pages.
Currently chains off of ::RPC::Dataset, but this may be changed later.

=cut

use Moose;
use namespace::autoclean;

BEGIN { extends 'Judoon::Web::Controller::RPC'; }
with qw(Judoon::Web::Controller::Role::ExtractParams);

use Data::Printer;

__PACKAGE__->config(
    action => {
        base => { Chained => '/rpc/dataset/chainpoint', PathPart => 'page', },
    },
    rpc => {
        template_dir => 'page',
        stash_key    => 'page',
        api_path     => 'page',
    },
);




=head2 object_GET (after)

After L<RPC/object_GET>, set up the stash parameters the page's edit
page will need.

=cut

after object_GET => sub {
    my ($self, $c) = @_;

    my @page_columns = $c->req->get_object(0)->[0]->page_columns;
    $c->stash->{page_column}{list} = \@page_columns;

    my $view = $c->req->param('view') // '';
    if ($view eq 'preview') {
        $c->stash->{page_column}{templates}
            = [map {$_->template_to_jquery} @page_columns];
        $c->stash->{template} = 'page/preview.tt2';
        $c->detach();
    }

    my %used;
    for my $page_col (@page_columns) {
        for my $node (map {$_->decompose} $page_col->template_to_objects()) {
            next unless ($node->type eq 'variable');
            push @{$used{$node->name}}, $page_col->title;
        }
    }
    my @headers_used = map {{
        title => $_->name, used_in => join(', ', @{$used{$_->shortname} || []}),
    }} $c->req->get_chained_object(0)->[0]->ds_columns;
    $c->stash->{dataset}{headers_used} = \@headers_used;
};


=head2 object_DELETE (after)

return to user overview instead of page list

=cut

after object_DELETE => sub {
    my ($self, $c) = @_;
    my @captures = @{$c->req->captures};
    pop @captures; pop @captures;
    $self->go_here($c, '/user/edit', \@captures);
};


__PACKAGE__->meta->make_immutable;

1;
__END__
