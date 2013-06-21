package t::Role::Schema;

use Test::Roo::Role;

require Test::DBIx::Class;

use Judoon::Tmpl;
use MooX::Types::MooseLike::Base qw(InstanceOf HashRef);
use Try::Tiny;


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



sub init_fixtures {
    my ($self) = @_;

    try {
        $self->load_fixtures('basic');
    }
    catch {
        my $exception = $_;
        BAIL_OUT( 'Fixture creation failed: ' . $exception );
    };
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
    reset_schema();
    return;
}



has testuser => (
    is  => 'lazy',
    isa => HashRef,
);
sub _build_testuser {
    return {
        username => 'testuser', password => 'testpass',
        name => 'Test User', email_address => 'testuser@example.com',
    };
}

has users => (
    is  => 'lazy',
    isa => HashRef,
);
sub _build_users {
    my ($self) = @_;
    return { testuser => $self->testuser };
}



has fixtures => (
    is => 'lazy',
    isa => HashRef,
);
sub _build_fixtures {
    return {
        basic => sub {
            my ($self) = @_;
            $self->schema()->resultset('TtDscolumnDatatype')->populate([
                ['id','data_type',],
                [1,'text',],[2,'numeric',],[3,'datetime',],[4,'currency',],
            ]);
            $self->schema()->resultset('TtAccessionType')->populate([
                ['id','accession_type','accession_domain'],
                [1,  'entrez_gene_id',     'biology',],
                [2,  'entrez_gene_symbol', 'biology',],
                [3,  'entrez_refseq_id',   'biology',],
                [4,  'entrez_protein_id',  'biology',],
                [5,  'entrez_unigene_id',  'biology',],
                [6,  'pubmed_id',          'biology',],
                [7,  'uniprot_acc',        'biology',],
                [8,  'uniprot_id',         'biology',],
                [9,  'flybase_id',         'biology',],
                [10, 'wormbase_id',        'biology',],
            ]);


            my $user_rs = $self->schema()->resultset('User');
            my $user = $user_rs->find({username => $self->testuser()->{username}})
                // $user_rs->create_user($self->testuser());

            my $dataset = $user->import_data_by_filename('t/etc/data/basic.xls');
            $dataset->create_basic_page();
        },
        clone_set => sub {
            my ($self) = @_;

            my $user_rs = $self->schema()->resultset('User');
            my $user = $user_rs->find({username => $self->testuser()->{username}})
                // $user_rs->create_user($self->testuser());

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
    };
}




1;
__END__
