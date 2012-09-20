#/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use lib q{t/lib};

use Test::More;
use Test::Fatal;
use t::DB;

use Archive::Extract;
use File::Spec;
use File::Temp qw(tempdir);
use HTTP::Request::Common;
use JSON qw(decode_json);
use Judoon::Standalone;
use Plack::App::CGIBin;
use Plack::App::File;
use Plack::App::URLMap;
use Plack::Test;

my $schema = t::DB::get_schema();
my $page = $schema->resultset('Page')->first();
ok my $standalone = Judoon::Standalone->new({page => $page}),
    'can create standalone object';
$standalone->build();
my $archive_path = $standalone->compress('tar.gz');
my $archive = Archive::Extract->new(archive => $archive_path);
my $dir = tempdir(CLEANUP => 1);
$archive->extract(to => $dir);

my $urlmap   = Plack::App::URLMap->new();
my $cgi_app  = Plack::App::CGIBin->new(root => File::Spec->catdir($dir,'judoon','cgi-bin'))->to_app;
my $root_app = Plack::App::File->new(  root => File::Spec->catdir($dir,'judoon'))->to_app;
$urlmap->map('/cgi-bin' => $cgi_app);
$urlmap->map('/' => $root_app);
test_psgi $urlmap->to_app, sub {
    my $cb = shift;
    my $res = $cb->(GET 'index.html');
    like $res->content(), qr{Cell Migration Consortium}, 'got index page';

    $res = $cb->(GET '/cgi-bin/data.cgi');
    is $res->content_type, 'application/json', 'got JSON response';
    like $res->content, qr{Va Bene}, 'found valid data';

    my @basic_search = query_result($cb, {search => 'Bene'});
    is @basic_search, 1, 'found 1 expected entry';

    my @ages = qw(1 14 2 5 8);
    my @sorted = query_result($cb, {sortby => [[1,'asc'],],});
    is_deeply [map {$_->{Age}} @sorted], \@ages, 'data is properly sorted';

    my @rsorted = query_result($cb, {sortby => [[1,'desc'],],});
    is_deeply [map {$_->{Age}} @rsorted], [reverse @ages],
        'data is properly reverse sorted';

    my @page = query_result($cb, {sortby => [[0,'asc'],], start => 1, count => 2,});
    is_deeply [map {$_->{Name}} @page], ['Chloe', 'Goochie',], 'can page corectly';
};


done_testing();


sub query_result {
    my ($cb, $args) = @_;
    $args ||= {};

    my %params = (
        sSearch        => $args->{search} || q{},
        iDisplayLength => $args->{count}  || 10,
        iDisplayStart  => $args->{start}  || 0,
    );

    if (my $sorts = $args->{sortby}) {
        my $i = 0;
        for my $sort (@$sorts) {
            $params{"iSortCol_$i"} = $sort->[0];
            $params{"sSortDir_$i"} = $sort->[1];
            $i++;
        }
        $params{iSortingCols} = $i;
    }

    my $query = join '&', map {"$_=".$params{$_}} keys %params;
    my $res = $cb->(GET "/cgi-bin/data.cgi?$query");
    return @{decode_json($res->content)->{tmplData}};
}
