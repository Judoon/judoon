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


=head2 add_object

Add a new page linked to the parent dataset.

=cut

override add_object => sub {
    my ($self, $c, $params) = @_;
    return $c->stash->{dataset}{object}->create_related('pages', {
        title => '', preamble => '', postamble => '',
    });
};


=head2 get_object

Fetch a page from the database.

=cut

override get_object => sub {
    my ($self, $c) = @_;
    return $c->stash->{dataset}{object}->pages_rs->find({id => $c->stash->{page}{id}});
};


=head2 edit_object

Update the page in the database.

=cut

override edit_object => sub {
    my ($self, $c, $params) = @_;
    my %valid = map {my $o = $_; s/^page\.//; $_ => ($params->{$o} // '')}
        grep {m/^page\./} keys %$params;
    return $c->stash->{page}{object}->update(\%valid);
};


=head2 object_GET (after)

After L<RPC/object_GET>, set up the stash parameters the page's edit
page will need.

=cut

after object_GET => sub {
    my ($self, $c) = @_;

    my @page_columns = $c->stash->{page}{object}->page_columns;
    $c->stash->{page_columns} = \@page_columns;

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
    }} $c->stash->{dataset}{object}->ds_columns;
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


=head2 delete_object

delete the page

=cut

override delete_object => sub {
    my ($self, $c) = @_;
    $c->stash->{page}{object}->delete;
};



__PACKAGE__->meta->make_immutable;

1;
__END__
