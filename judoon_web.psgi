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
use Moose::Util ();
use Plack::Builder;

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


    # mount app
    mount '/' => Judoon::Web->apply_default_middlewares(Judoon::Web->psgi_app);
};

