#!/usr/bin/env perl

# Author:       Fitz Elliott <felliott@virginia.edu>
# Date Created: Thu Apr 18 14:51:16 2013
# Description:  rebuild Judoon's ElasticSearch index

use strict;
use warnings;
use autodie;
use open qw( :encoding(UTF-8) :std );
use feature ':5.14';

use FindBin qw($Bin);
use lib "$Bin/../../../lib";
use lib "$Bin/../../../t/lib";

use Data::Printer;
use Getopt::Long;
use HTML::Scrubber;
use HTML::Selector::XPath::Simple;
use Judoon::Schema;
use Judoon::Search;
use Pod::Usage;
use t::DB;


main: {
    my ($help);
    GetOptions('help|h' => \$help) or pod2usage(2);
    pod2usage(1) if ($help);

    my $mech   = t::DB::new_mech();
    my $model  = Judoon::Search->new;
    my $index  = $model->namespace('judoon')->index;
    my $domain = $model->domain('judoon');

    print "Creating index...";
    $index->delete();
    $index->create();
    print " Done!\n";


    print "Beginning indexing\n";
    # index static pages on our website
    # fixme: this should probably be a crawler
    print "  static pages...";
    my @static_pages = qw(about news get_started);
    for my $static_page (@static_pages) {
        $mech->get("/$static_page");
        my $sel = HTML::Selector::XPath::Simple->new($mech->content);
        my $content = join ' ', map {ref($_) ? $_->as_text : $_}
            $sel->select('#content p');

        (my $title = $sel->select('title')) =~ s/ \| Judoon//;
        my $description = join '', map {$_->{content}}
             $sel->{tree}->findnodes('//meta[@name="description"]');

        my $webpage = $domain->create(
            webpage => {
                title       => $title,
                description => $description,
                content     => $content,
                url         => Judoon::Web->uri_for("/$static_page"),
            }
        );
    }
    print " Done!\n";

    # index contents of our database.
    my $schema = Judoon::Schema->connect('Judoon::Schema');

    my $user_rs = $schema->resultset('User');
    my %user_map;
    while (my $user = $user_rs->next) {
        my $user_doc = $domain->create(
            user => {
                username => $user->username,
                name     => $user->name,
                email_address => $user->email_address,
            },
        );
        $user_map{$user->username} = $user_doc;
    }

    # start with datasets
    print "  datasets...";
    my $ds_rs = $schema->resultset('Dataset');
    while ( my $dataset = $ds_rs->next ) {
        my $ds_doc = $domain->create(
            dataset => {
                title       => $dataset->name,
                description => $dataset->notes,
                content     => $dataset->notes,
                url         => Judoon::Web->uri_for_action(
                    '/private/dataset/object',
                    [$dataset->user->username, $dataset->id]
                ),

                private     => $dataset->is_private,

                owner       => $user_map{$dataset->user->username},
                data        => join("\n", map { join("\t", map {$_ // q()} @$_) } @{$dataset->data}),
                headers     => join("\t", $dataset->long_headers),
                nbr_rows    => $dataset->nbr_rows,
                nbr_columns => $dataset->nbr_columns,
                created     => $dataset->created,
                updated     => $dataset->modified,
            }
        );
    }
    print " Done!\n";


    my $html_scrubber = HTML::Scrubber->new(allow => []);

    my $page_rs = $schema->resultset('Page');
    print "  pages...";
    while ( my $page = $page_rs->next ) {
        my $page_doc = $domain->create(
            page => {
                title       => $page->title,
                description => $html_scrubber->scrub($page->preamble),
                content     => join(' ',
                    map { $html_scrubber->scrub($_) }
                        ($page->preamble, $page->postamble)
                ),
                url         => Judoon::Web->uri_for_action(
                    '/private/page/object',
                    [$page->dataset->user->username,
                     $page->dataset->id, $page->id,]
                ),

                private     => $page->is_private,

                owner       => $user_map{$page->dataset->user->username},
                data        => join("\n", map { join("\t", map {$_ // q()} @$_) } @{$page->data_table}),
                headers     => join("\t", map {$_ // q()} @{$page->headers}),
                nbr_rows    => $page->nbr_rows,
                nbr_columns => $page->nbr_columns,
                created     => $page->created,
                updated     => $page->modified,
            }
        );
    }
    print " Done!\n";

    $schema->storage->disconnect;
    done();
}

sub done {
    t::DB::get_schema()->storage->disconnect;
    exit;
}


__END__

=head1 NAME

reindex.pl -- rebuild Judoon's ElasticSearch index

=head1 SYNOPSIS

 $ perl share/scripts/search/reindex.pl

=head1 OPTIONS

=over

=item B<-h, --help>

Prints this message and exits.

=back
