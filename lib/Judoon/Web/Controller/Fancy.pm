package Judoon::Web::Controller::Fancy;

use Moose;
use namespace::autoclean;

BEGIN { extends 'Judoon::Web::Controller'; }
with qw(
    Judoon::Web::Controller::Role::ExtractParams
);

use Judoon::Tmpl;
use Safe::Isa;
use Try::Tiny;


sub base : Chained('/user/id') PathPart('fancy') CaptureArgs(0) {}

sub yep : Chained('base') PathPart('') Args(0) {
    my ($self, $c) = @_;
    $c->stash->{template} = 'fancy/base.tt2';
}

sub page_id : Chained('base') PathPart('page') CaptureArgs(1) {
    my ($self, $c, $page_id) = @_;
    die 'Well, shit.' unless ($c->user);
    my $page = $c->user->my_pages->find({id => $page_id});
    $c->stash->{page}{object} = $page;
}


sub page_view : Chained('page_id') PathPart('') Args(0) {
    my ($self, $c) = @_;

    my $page = $c->stash->{page}{object};

    $c->stash->{dataset}{id} = $page->dataset->id;

    $c->stash->{page_column}{list} = [$page->page_columns_ordered->hri->all];
    for my $column (@{$c->stash->{page_column}{list}}) {
        my $tmpl = Judoon::Tmpl->new_from_native($column->{template});
        $column->{js_template} = $tmpl->to_jstmpl;
    }

    $c->stash->{template} = 'fancy/page-view.tt2';
}

sub page_static : Chained('page_id') PathPart('static') Args(0) {
    my ($self, $c) = @_;
    $c->stash->{template} = 'fancy/page-view-static.tt2';
}

1;
__END__
