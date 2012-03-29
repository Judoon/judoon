#/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use Data::Section::Simple qw(get_data_section);


use_ok 'Judoon::Template::Translator';

my $translator = Judoon::Template::Translator->new;



my @dialects = qw(Native WebWidgets JQueryTemplate);
my @test_types = qw(
    text_only data_only url_only newline_only
    combined
);

my %templates;
for my $dialect (@dialects) {
    for my $test_type (@test_types) {
        $templates{$dialect}->{$test_type}
            = get_data_section( lc($dialect} . '-' . $test_type )
                or die "Unable to find test template for $dialect / $test_type";
    }
}


my @comparisons = map {my $orig = $_; map {[$orig, $_]} @dialects;} @dialects;
for my $comparison (@comparisons) {
    my ($from_dialect, $to_dialect) = @_;

    subtest "Translating $from_dialect => $to_dialect" => sub {
        for my $test (@test_types) {
            my $output = $translator->translate({
                from     => $from_dialect,
                to       => $to_dialect,
                template => $templates{$from_dialect}->{$test},
            });
            is $output, $template{$to_dialect}{$test}, "translated $test ok";
        }
    };
}


# versioning syntax
# my $output = $translator->translate({
#     from         => 'Judoon::WebWidgets',
#     from_version => 1,
#     to           => 'JQuery::Template',
#     to_version   => 1,
#     template     => $template,
# });



done_testing();


__DATA__
@@ webwidgets-text_only
