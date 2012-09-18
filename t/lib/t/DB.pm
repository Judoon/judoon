package t::DB;

use strict;
use warnings;

require Test::DBIx::Class;
use Test::More;
use Test::WWW::Mechanize::Catalyst;

use Judoon::Web ();
use Try::Tiny;

my $schema;
sub get_schema { return $schema; }

sub import {
    my ($self) = @_;

    Test::DBIx::Class->import({
        schema_class => 'Judoon::DB::User::Schema',
        connect_opts => {
            on_connect_do => [
                q{ATTACH DATABASE ':memory:' AS data;}
            ],
        },
    }, qw(Schema));
    $schema = Schema();

    try {
        install_fixtures();
    }
    catch {
        my $exception = $_;
        BAIL_OUT( 'Fixture creation failed: ' . $exception );
    };
}

sub new_mech {
    Judoon::Web->model('User')->schema($schema);
    return Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'Judoon::Web');
}


my %testuser = (
    username => 'testuser', password => 'testpass',
    name => 'Test User', email_address => 'testuser@example.com',
);
sub get_testuser { return \%testuser; }

sub install_fixtures {
    my $user = get_schema()->resultset('User')->create_user(get_testuser());
    open my $TEST_XLS, '<', 't/etc/data/basic.xls'
        or die "Can't open test spreadsheet: $!";
    my $dataset = $user->import_data($TEST_XLS);
    close $TEST_XLS;
    $dataset->create_basic_page();
}

1;
__END__
