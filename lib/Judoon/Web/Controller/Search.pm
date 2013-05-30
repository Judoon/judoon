package Judoon::Web::Controller::Search;

use Moose;
use namespace::autoclean;

BEGIN { extends 'Judoon::Web::Controller'; }


sub base : Chained('/') PathPart('search') CaptureArgs(0) {
    my ($self, $c) = @_;

    my $data = $c->req->data || $c->req->params;

    my $domain     = $c->model('Search')->domain('judoon');
    my $view       = $domain->view;

    my $web_search = $view->type('webpage')->queryb({_all => $data->{q},})
        ->highlight('body')->highlighting(
            pre_tags    =>  [ '<em>',  '<b>'  ],
            post_tags   =>  [ '</em>', '</b>' ],
            encoder     => 'html',
        );
    my $web_iter   = $web_search->search->as_results();
    my @web_results;
    while (my $result = $web_iter->next) {
        push @web_results, {
            webmeta    => $result->result->{_source},
            highlights => [$result->highlight('body')],
            body       => substr($result->result->{_source}{content}, 0, 100) . '...',
        };
    }
    $c->stash->{search}{web_results} = \@web_results;


    my @data_indexes = ('public_data');
    push @data_indexes, 'private_data' if( $c->user_exists );

    my $data_search = $view->type('dataset')->queryb({_all => $data->{q},});
        # ->filterb(private => 0);
    my $data_iter   = $data_search->search->as_results();
    my @data_results;
    while (my $result = $data_iter->next) {
        push @data_results, {
            webmeta    => $result->result->{_source},
            highlights => [$result->highlight('body')],
            body       => substr($result->result->{_source}{content}, 0, 100) . '...',
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
