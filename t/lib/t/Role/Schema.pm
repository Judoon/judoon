package t::Role::Schema;

=pod

=encoding utf-8

=head1 NAME

t::Role::Schema - a role for setting up a test database

=head1 DESCRIPTION

Test files using L</Test::Roo> can consume this role to get a
temporary instance of L<Judoon::Schema> to test against.

=cut


use Judoon::Tmpl;
use MooX::Types::MooseLike::Base qw(InstanceOf HashRef);
require Test::DBIx::Class;
use Try::Tiny;

use Test::Roo::Role;

=head1 ATTRIBUTES / METHODS

=head2 schema_config / _build_schema_config

Default configuration for our test database.

=cut

has schema_config => (
    is  => 'lazy',
    isa => HashRef,
);
sub _build_schema_config {
    my ($self) = @_;
    return {
        schema_class => 'Judoon::Schema',
        traits       => 'Testpostgresql',
        connect_opts => {
            quote_char     => q{"},
            name_sep       => q{.},
            pg_enable_utf8 => 1,
            on_connect_do  => 'SET client_min_messages=WARNING;',
        },
    },
}


=head2 schema / _build_schema

Build a connection to a test schema using L</Test::DBIx::Class> and
the configuration defined in C<< $self->schema_config >>.

=cut

has schema => (
    is      => 'lazy',
    isa     => InstanceOf['Judoon::Schema'],
    handles => ['resultset'],
);
sub _build_schema {
    my ($self) = @_;
    Test::DBIx::Class->import($self->schema_config, qw(Schema reset_schema));
    return Schema();
}



=head2 users / _build_users

A C<HashRef> of well-known users. Suitable for passing to
C<< Judoon::Schema::ResultSet::User->create_user() >>.

=cut

has users => (
    is  => 'lazy',
    isa => HashRef,
);
sub _build_users {
    my ($self) = @_;
    return {
        testuser => {
            username => 'testuser', password => 'testpass',
            name => 'Test User', email_address => 'testuser@example.com',
        },
        me  => {
            username => 'me', password => 'mypassword',
            name => 'Me Who I Am', email_address => 'me@example.com',
        },
        you => {
            username => 'you', password => 'yourpassword',
            name => 'You Who You Are', email_address => 'you@example.com',
        },
    };
}


=head2 fixtures / _build_fixtures

A C<HashRef> of fixture definitions.  A fixture value is a code ref
that populates data into C<< $self->schema >>.

=cut

has fixtures => (
    is  => 'lazy',
    isa => HashRef,
);
sub _build_fixtures {
    return {

        # standard fixtures needed by everyone
        init  => sub {
            my ($self) = @_;
            $self->schema()->resultset('TtDscolumnDatatype')->populate([
                ['data_type',                           ],
                ['CoreType_Text',                       ],
                ['CoreType_Numeric',                    ],
                ['CoreType_Datetime',                   ],
                ['Biology_Accession_Entrez_GeneId',     ],
                ['Biology_Accession_Entrez_GeneSymbol', ],
                ['Biology_Accession_Entrez_RefseqId',   ],
                ['Biology_Accession_Entrez_ProteinId',  ],
                ['Biology_Accession_Entrez_UnigeneId',  ],
                ['Biology_Accession_Pubmed_Pmid',       ],
                ['Biology_Accession_Uniprot_Acc',       ],
                ['Biology_Accession_Uniprot_Id',        ],
                ['Biology_Accession_Flybase_Id',        ],
                ['Biology_Accession_Wormbase_Id',       ],
                ['Biology_Accession_Cmkb_ComplexAcc',   ],
                ['Biology_Accession_Cmkb_FamilyAcc',    ],
                ['Biology_Accession_Cmkb_OrthologAcc',  ],
            ]);
        },

        # a simple one-user, one-ds, one-page fixture
        basic => sub {
            my ($self) = @_;

            my $user_rs = $self->schema()->resultset('User');
            my $user = $user_rs->find({username => $self->users->{testuser}->{username}})
                // $user_rs->create_user($self->users->{testuser});

            my $dataset = $user->import_data_by_filename('t/etc/data/basic.xls');
            $dataset->create_basic_page();
        },

        # fixtures for testing Page cloning
        clone_set => sub {
            my ($self) = @_;

            my $user_rs = $self->schema()->resultset('User');
            my $user = $user_rs->find({username => $self->users->{testuser}->{username}})
                // $user_rs->create_user($self->users->{testuser});

            my $clone1_ds = $user->import_data_by_filename('t/etc/data/clone1.xls');
            $clone1_ds->create_basic_page();
            my $first_page = $clone1_ds->create_related('pages', {
                title     => q{IMDB.com's Top 5 Movies of All Time},
                preamble  => q{These are the best movies as voted by the users of IMDB.com},
                postamble => q{All data from IMDB.com},
            });

            my @columns = (
                ['Name / Director', '<a href="{{imdb}}">{{title}}</a><br><strong>Directed By:</strong> {{director}}'],
                ['Year',   '{{year}}',],
                ['Rating', '{{rating}}'],
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

        # fixtures for testing the Judoon API
        api => sub {
            my ($self) = @_;
            my $user_rs = $self->schema()->resultset('User');

            # build fixtures for me user
            my %me = (object => $user_rs->create_user( $self->users->{'me'} ));
            my $my_pub_ds
                = $me{object}->import_data_by_filename('t/etc/data/api/me-public.xls')
                    ->update({permission => 'public'});
            my $my_priv_ds
                = $me{object}->import_data_by_filename('t/etc/data/api/me-private.xls');
            $me{public_ds} = {
                object       => $my_pub_ds,
                public_page  => $my_pub_ds->create_basic_page->update({permission => 'public'}),
                private_page => $my_pub_ds->create_basic_page,
            };
            $me{private_ds} = {
                object       => $my_priv_ds,
                public_page  => $my_priv_ds->create_basic_page->update({permission => 'public'}),
                private_page => $my_priv_ds->create_basic_page,
            };

            # build fixtures for you user
            my %you = (object => $user_rs->create_user( $self->users->{'you'} ));
            my $you_pub_ds
                = $you{object}->import_data_by_filename('t/etc/data/api/you-public.xls')
                    ->update({permission => 'public'});
            $you{public_ds} = {
                object      => $you_pub_ds,
                public_page => $you_pub_ds->create_basic_page->update({permission => 'public'}),
            };
        },

        # fixture for testing Judoon::Lookups
        lookup => sub {
            my ($self) = @_;
            my $user_rs   = $self->schema()->resultset('User');
            my $me        = $user_rs->find_or_create( $self->users->{me} );
            my $active_ds = $me->import_data_by_filename('t/etc/data/lookup/me-active.xls');
            my $lookup_ds = $me->import_data_by_filename('t/etc/data/lookup/me-lookup.xls');
        },
    };
}


=head3 add_fixture( $fixture_name, $code )

Add a new fixture definition to the internal fixtures
dictionary. C<$code> will receive C<$self> as its only argument.

=head3 load_fixtures( @fixture_names )

Run the fixture code found in C<< $self->fixtures >> for each name in
C<@fixture_names>.  Fixtures are run in passed order.

=head3 reset_fixtures()

Wipe the Judoon schema and delete all user schemas.

=cut

sub add_fixture {
    my ($self, $key, $code) = @_;
    $self->fixtures->{$key} = $code;
}

sub load_fixtures {
    my ($self, @fixtures) = @_;

    for my $fixture (@fixtures) {
        my $fixture_sub = $self->fixtures->{$fixture}
            or die "No such fixture set: $fixture";
        $fixture_sub->($self);
    }

    return;
}

sub reset_fixtures {
    my ($self) = @_;

    for my $user ($self->schema->resultset('User')->all) {
        $self->schema->storage->dbh->do(
            'DROP SCHEMA ' . $user->schema_name . ' CASCADE'
        );
    }
    reset_schema();
    return;
}


1;
__END__
