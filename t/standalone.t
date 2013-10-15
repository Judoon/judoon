#!/usr/bin/env perl

use Archive::Extract;
use File::Spec;
use File::Temp qw(tempdir);
use HTTP::Request::Common;
use Judoon::Standalone;
use Plack::App::CGIBin;
use Plack::App::File;
use Plack::App::URLMap;
use Plack::Test;
use Test::Fatal;

use Test::Roo;
use lib 't/lib';
with 't::Role::Schema';


after setup => sub {
    my ($self) = @_;
    $self->load_fixtures(qw(init basic));
};

has standalone => (is => 'rw');

test 'basic' => sub {
    my ($self) = @_;
    my $page = $self->schema->resultset('Page')->first();
    ok my $standalone = Judoon::Standalone->new({page => $page}),
        'can create standalone object';
    $self->standalone($standalone);
};

test 'save to zip' => sub {
    my ($self) = @_;
    my $archive_path = $self->standalone->compress('zip');
    ok -e $archive_path, 'archive exists';
    my $archive = Archive::Extract->new(archive => $archive_path);
    ok $archive->is_zip, 'saved archive isa zip file';
    test_contents($archive);
};

test 'save to tar' => sub {
    my ($self) = @_;
    my $archive_path = $self->standalone->compress('tar.gz');
    ok -e $archive_path, 'archive exists';
    my $archive = Archive::Extract->new(archive => $archive_path);
    ok $archive->is_tgz, 'saved archive isa tar.gz file';
    test_contents($archive);
};

run_me();
done_testing();



sub test_contents {
    my ($archive) = @_; # an Archive::Extract object

    my $dir = tempdir(CLEANUP => 1);
    $archive->extract(to => $dir);

    my @has = qw(
        index.html cgi-bin/data.cgi cgi-bin/database.tab js/plugins.min.js
        .htaccess css/bootstrap.min.css css/bootstrap-responsive.min.css
        js/vendor/bootstrap.min.js js/vendor/jquery-1.8.1.min.js
        js/vendor/jquery.dataTables.min.js js/vendor/handlebars.min.js
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
