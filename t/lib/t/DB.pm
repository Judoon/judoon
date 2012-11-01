package t::DB;

use strict;
use warnings;

require Test::DBIx::Class;
use Test::More;
use Test::WWW::Mechanize::Catalyst;

use Judoon::Tmpl;
use Judoon::Web ();
use Try::Tiny;

my $schema;
sub get_schema { return $schema; }

sub import {
    my ($self) = @_;

    Test::DBIx::Class->import({
        schema_class => 'Judoon::Schema',
        traits       => 'Testpostgresql',
        connect_opts => {
            quote_char     => q{"},
            name_sep       => q{.},
            pg_enable_utf8 => 1,
            on_connect_do => 'SET client_min_messages=WARNING;',
        },
    }, qw(Schema));
    $schema = Schema();

    try {
        load_fixtures('basic');
    }
    catch {
        my $exception = $_;
        BAIL_OUT( 'Fixture creation failed: ' . $exception );
    };
}

sub new_mech {
    $ENV{PLACK_ENV} = 'testsuite';
    Judoon::Web->model('User')->schema($schema);
    return Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'Judoon::Web');
}


my %testuser = (
    username => 'testuser', password => 'testpass',
    name => 'Test User', email_address => 'testuser@example.com',
);
sub get_testuser { return \%testuser; }



my %fixture_subs = (
    basic => sub {
        my $user_rs = get_schema()->resultset('User');
        my $user = $user_rs->find({username => get_testuser()->{username}})
            // $user_rs->create_user(get_testuser());

        my $dataset = $user->import_data_by_filename('t/etc/data/basic.xls');
        $dataset->create_basic_page();
    },
    clone_set => sub {
        my $user_rs = get_schema()->resultset('User');
        my $user = $user_rs->find({username => get_testuser()->{username}})
            // $user_rs->create_user(get_testuser());

        my $clone1_ds = $user->import_data_by_filename('t/etc/data/clone1.xls');
        $clone1_ds->create_basic_page();
        my $first_page = $clone1_ds->create_related('pages', {
            title     => q{IMDB.com's Top 5 Movies of All Time},
            preamble  => q{These are the best movies as voted by the users of IMDB.com},
            postamble => q{All data from IMDB.com},
        });

        my @columns = (
            ['Name / Director', '<a href="{{=imdb}}">{{=title}}</a><br><strong>Directed By:</strong> {{=director}}'],
            ['Year',   '{{=year}}',],
            ['Rating', '{{=rating}}'],
        );

        my $i = 1;
        for my $column (@columns) {
            my $page_col = $first_page->add_to_page_columns({
                title => $column->[0], sort => $i++,
                template => Judoon::Tmpl->new_from_jstmpl($column->[1]),
            });
        }

        my $clone2_ds = $user->import_data_by_filename('t/etc/data/clone2.xls');
        $clone2_ds->create_basic_page();
    },
);

sub load_fixtures {
    my (@fixtures) = @_;

    for my $fixture (@fixtures) {
        my $fixture_sub = $fixture_subs{$fixture}
            or die "No such fixture set: $fixture";
        $fixture_sub->();
    }

    return;
}


1;
__END__
