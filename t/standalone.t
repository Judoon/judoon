#!/usr/bin/env perl

use strict;
use warnings;

use lib q{t/lib};

use Test::More;
use Test::Fatal;
use t::DB;

use Archive::Extract;
use File::Spec;
use File::Temp qw(tempdir);
use HTTP::Request::Common;
use Judoon::Standalone;
use Plack::App::CGIBin;
use Plack::App::File;
use Plack::App::URLMap;
use Plack::Test;

my $schema = t::DB::get_schema();
my $page = $schema->resultset('Page')->first();
ok my $standalone = Judoon::Standalone->new({page => $page}),
    'can create standalone object';

subtest 'save to zip' => sub {
    my $archive_path = $standalone->compress('zip');
    ok -e $archive_path, 'archive exists';
    my $archive = Archive::Extract->new(archive => $archive_path);
    ok $archive->is_zip, 'saved archive isa zip file';
    test_contents($archive);
};

subtest 'save to tar' => sub {
    my $archive_path = $standalone->compress('tar.gz');
    ok -e $archive_path, 'archive exists';
    my $archive = Archive::Extract->new(archive => $archive_path);
    ok $archive->is_tgz, 'saved archive isa tar.gz file';
    test_contents($archive);
};

done_testing();



sub test_contents {
    my ($archive) = @_; # an Archive::Extract object

    my $dir = tempdir(CLEANUP => 1);
    $archive->extract(to => $dir);

    my @has = qw(
        index.html cgi-bin/data.cgi cgi-bin/database.tab js/plugins.min.js
        .htaccess css/bootstrap.min.css css/bootstrap-responsive.min.css
        js/vendor/bootstrap.min.js js/vendor/jquery-1.8.1.min.js
        js/vendor/jquery.dataTables.min.js js/vendor/jsrender.min.js
        js/vendor/modernizr-2.6.1-respond-1.1.0.min.js
    );
    for my $has (@has) {
        ok -e File::Spec->catdir($dir, 'judoon', $has), "has $has";
    }

    ok -x File::Spec->catdir($dir, 'judoon/cgi-bin/data.cgi'),
        'cgi is executable';


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
    };

    return;
}
