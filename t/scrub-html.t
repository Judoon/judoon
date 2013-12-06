#!/usr/bin/env perl

use utf8;

use Data::Section::Simple qw(get_data_section);

use Test::Roo;
use lib 't/lib';
with 'Judoon::Role::ScrubHTML', 't::Role::HtmlFixtures';

test 'scrubbing' => sub {
    my ($self) = @_;

    my $fixtures = $self->html_fixtures;
    for my $test (keys $fixtures) {
        is $self->scrub_html_string($fixtures->{$test}{tainted}),
            $fixtures->{$test}{scrubbed_string},
            "got expected scrubbed string for ${test}";
        is $self->scrub_html_block($fixtures->{$test}{tainted}),
            $fixtures->{$test}{scrubbed_block},
            "got expected scrubbed block for ${test}";
    }
};

run_me();
done_testing();
