#!/usr/bin/env perl

use strict;
use warnings;

use feature ':5.10';

# set debugging env flags
BEGIN {

    $ENV{PLACK_ENV} //= '';

    if ($ENV{PLACK_ENV} =~ m/^development/) {
        $ENV{JUDOON_WEB_DEBUG}   = 1;
        $ENV{DBIC_TRACE}         = 1;
        $ENV{DBIC_TRACE_PROFILE} = 'console';
    }
    elsif ($ENV{PLACK_ENV} eq 'test_deploy') {
        $ENV{JUDOON_WEB_DEBUG}   = 1;
        $ENV{DBIC_TRACE}         = 1;
        $ENV{DBIC_TRACE_PROFILE} = 'console_monochrome';
    }

}


use Judoon::Web;
use MIME::Types;
use Moose::Util ();
use Plack::Builder;
use Plack::Middleware::SetAccept;


builder {

    # turn on debugging panels
    if ($ENV{PLACK_ENV} =~ m/^development/) {
        enable 'Plack::Middleware::Debug', panels => [qw(
            Environment Response Timer Memory Session DBITrace
            CatalystLog ModuleVersions Parameters
        )];
    }

    # turn on heavyweight debugging panels
    if ($ENV{PLACK_ENV} eq 'development-heavy') {
        enable 'Debug::DBIC::QueryLog';

        Moose::Util::apply_all_roles(
            Judoon::Web->model('User'),
            'Catalyst::TraitFor::Model::DBIC::Schema::QueryLog::AdoptPlack'
        );
    }

    enable "Plack::Middleware::Static",
        path => qr{^/static/}, root => './root/';

    # requests to /api with extensions set the Accept header
    my $mimetypes = MIME::Types->new;
    my %mapping = map {$_ => $mimetypes->mimeTypeOf($_)->type()}
        qw(tsv csv xls xlsx zip tgz);
    enable_if { $_[0]->{PATH_INFO} =~ m{^/api/}; }
        SetAccept => from => 'suffix', mapping => \%mapping;

    # mount app
    mount '/' => Judoon::Web->apply_default_middlewares(Judoon::Web->psgi_app);


};

