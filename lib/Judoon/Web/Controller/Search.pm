package Judoon::Web::Controller::Search;

use Moose;
use namespace::autoclean;

BEGIN { extends 'Judoon::Web::Controller'; }


sub base : Chained('/') PathPart('search') CaptureArgs(0) {
    my ($self, $c) = @_;

    my $data = $c->req->data || $c->req->params;

    my $domain     = $c->model('Search')->domain('judoon');
    my $view       = $domain->view;
    my $web_view   = $view->highlight(qw(title content))->highlighting(
        pre_tags  => [ '<strong>',  ],
        post_tags => [ '</strong>', ],
        encoder   => 'html',
        fragment_size => 50,
    );

    my $web_search = $web_view->type('webpage')->queryb({_all => $data->{q},});
    my $web_iter   = $web_search->search->as_results();
    my @web_results;
    while (my $result = $web_iter->next) {
        my $raw = $result->result->{_source};
        my $object = $result->object;
        push @web_results, {
            %$raw,
            context => [$result->highlight('title'), $result->highlight('content')],
            retrieved_fmt => $object->retrieved->ymd,
        };
    }
    $c->stash->{search}{web_results} = \@web_results;


    my $data_search = $web_view->type('page')->queryb({_all => $data->{q},})
        ->filterb(private => 0);
    my $data_iter   = $data_search->search->as_results();
    my @data_results;
    while (my $result = $data_iter->next) {
        my $raw    = $result->result->{_source};
        my $object = $result->object;
        push @data_results, {
            %$raw,
            context => [$result->highlight('title'), $result->highlight('content')],
            retrieved_fmt => $object->retrieved->ymd,
            created_fmt   => $object->created->ymd,
        };
    }
    $c->stash->{search}{data_results} = \@data_results;
}

sub index :Chained('base') PathPart('') Args(0) {
    my ($self, $c) = @_;
    $c->stash->{template} = 'search/results.tt2';
}

__PACKAGE__->meta->make_immutable;
1;
