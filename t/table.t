#!/usr/bin/env perl

use Judoon::Table;
use Test::Fatal;

use Test::Roo;
use lib 't/lib';
with 't::Role::Schema';

after setup => sub {
    my ($self) = @_;
    $self->load_fixtures(qw(init api));
};


test basic => sub {
    my ($self) = @_;

    my $user_rs = $self->schema->resultset('User');
    my $me      = $user_rs->find({username => 'me'});
    my $ds      = $me->datasets->first;
    my $page    = $ds->pages->first;

    my @formats = qw(tsv csv xls xlsx);
    my @headers = qw(long short none);
    my @sources = ($ds, $page);

    for my $source (@sources) {
        for my $format (@formats) {
            for my $header_type (@headers) {
                ok !exception {
                    Judoon::Table->new({
                        data_source => $source,
                        header_type => $header_type,
                        format      => $format,
                    })->render();
                }, "can render " . ref($source) . " as $format with $header_type headers";
            }
        }
    }

};

run_me();
done_testing();
