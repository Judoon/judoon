#!/usr/bin/env perl

# This file tests the API's response to non-JSON Accept-Types

use Archive::Extract;
use File::Temp qw(tempfile tempdir);
use HTTP::Request::Common qw(GET);
use Spreadsheet::ParseExcel;
use Spreadsheet::ParseXLSX;
use Text::CSV;
use Test::Fatal;

use Test::Roo;
use lib 't/lib';
with 't::Role::Schema', 't::Role::Mech', 't::Role::WebApp', 't::Role::API',
    'Judoon::Role::JsonEncoder', 'Judoon::Role::MimeTypes';


after setup => sub {
    my ($self) = @_;
    $self->load_fixtures(qw(init api));
};

test 'basic' => sub {
    my ($self) = @_;

    my $user_rs = $self->schema->resultset('User');
    my $me      = $user_rs->find({username => 'me'});

    my $ds      = $me->datasets->first;
    my $ds_id   = $ds->id;
    my $ds_url  = "/api/datasets/$ds_id";
    subtest 'dataset - table' => sub { $self->fetch_tabular($ds_url, 'me'); };

    my $page      = $ds->pages->first;
    my $page_id   = $page->id;
    my $page_url  = "/api/pages/$page_id";
    subtest 'page - table' => sub { $self->fetch_tabular($page_url, 'me'); };
    subtest 'page - application' => sub {
        $self->fetch_application($page_url, 'me');
    };
};


run_me();
done_testing();


sub fetch_tabular {
    my ($self, $url, $user) = @_;


    my $tsv_sub = sub {
        Text::CSV->new({binary => 1, sep_char => "\t"})->getline_all($_[0]);
    };
    my $csv_sub = sub {
        Text::CSV->new({binary => 1})->getline_all($_[0]);
    };
    my $xls_sub  = sub { Spreadsheet::ParseExcel->new->parse($_[0]); };
    my $xlsx_sub = sub { Spreadsheet::ParseXLSX->new->parse($_[0]);  };

    my @tests = (
        ['tsv',  $tsv_sub,  ],
        ['csv',  $csv_sub,  ],
        ['xls',  $xls_sub,  ],
        ['xlsx', $xlsx_sub, ],
    );

    for my $test (@tests) {
        my ($type, $parse_sub) = @$test;

        $self->login( @{$self->users->{$user}}{qw(username password)} )
            unless ($user eq 'noone');

        my $r = GET($url, 'Accept' => $self->mime_type_for($type));
        $self->mech->request($r);
        my $file = $self->mech->content;
        open my $TABLE, '<', \$file;
        ok !exception { $parse_sub->($TABLE) }, "  ...is a readable $type";
        close $TABLE;

        $self->logout unless ($user eq 'noone');
    }
}


sub fetch_application {
    my ($self, $url, $user) = @_;


    my $zip_sub = sub {};
    my $tgz_sub = sub {};

    my @tests = (
        ['zip',  $zip_sub,  ],
        ['tgz',  $tgz_sub,  ],
    );

    for my $test (@tests) {
        my ($type, $parse_sub) = @$test;

        $self->login( @{$self->users->{$user}}{qw(username password)} )
            unless ($user eq 'noone');

        my $r = GET($url, 'Accept' => $self->mime_type_for($type));
        $self->mech->request($r);

        ok !exception {
            my ($tmp_fh, $tmp_path) = tempfile(UNLINK => 1);
            print {$tmp_fh} $self->mech->content;
            close $tmp_fh;
            my $archive = Archive::Extract->new(archive => $tmp_path, type => $type);
            my $dir     = tempdir(CLEANUP => 1);
            $archive->extract(to => $dir);
        }, "  ...is a readable $type";

        $self->logout unless ($user eq 'noone');
    }

}
