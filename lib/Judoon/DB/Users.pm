package Judoon::DB::Users;

use version; our $VERSION = '0.0.1';
use autodie;
use open qw( :encoding(UTF-8) :std );
use feature ':5.10';

use Moose;
with 'Judoon::DB::Roles::Deployer';
use namespace::autoclean;

use Data::Printer;
use DBI;
use JSON;
use Spreadsheet::Read;


has dbh => (is => 'ro', isa =>'DBI::db', lazy_build => 1);
sub _build_dbh {
    my ($self) = @_;
    return DBI->connect(
        'dbi:SQLite:dbname=judoon.sqlite', '', '',
        {
            AutoCommit => 1,
            RaiseError => 1,
        }
    );
}


sub import_data_for_user  {
    my ($self, $user_login, $fh) = @_;

    my $ref  = ReadData($fh, parser => 'xls');
    my $ds   = $ref->[1];
    my $data = $self->pivot_data($ds->{cell}, $ds->{maxrow}, $ds->{maxcol});

    return $self->add_dataset({
        user_login => $user_login, name => $ds->{label},
        original   => q{},         data => $data,
    });
}

sub pivot_data {
    my ($self, $data, $maxrow, $maxcol) = @_;

    shift @$data; # bye bye bogus row
    my $pivoted = [];
    for my $row_idx (0..$maxrow-1) {
        for my $col_idx (0..$maxcol-1) {
            $pivoted->[$row_idx][$col_idx] = $data->[$col_idx+1][$row_idx+1];
        }
    }

    return $pivoted;
}


sub get_user {
    my ($self, $login) = @_;
    my $sth = $self->dbh->prepare_cached('SELECT * FROM users WHERE login=?');
    $sth->execute($login);
    my $user = $sth->fetchrow_hashref();
    $sth->finish();
    return $user;
}
sub get_user_id { return $_[0]->get_user($_[1])->{id}; }


sub add_dataset {
    my ($self, $args) = @_;
    my $user_id = $self->get_user_id($args->{user_login});

    my $sth = $self->dbh->prepare_cached(
        'INSERT INTO datasets (user_id, name, notes, original, data) VALUES (?,?,?,?,?)'
    );
    $sth->execute($user_id, $args->{name}, '', $args->{original}, encode_json($args->{data}));
    my $ds_id = $self->dbh->last_insert_id(undef,undef,'datasets','id');

    my $data = $args->{data};
    my $headers = shift @$data;

    my $sort = 1;
    for my $header (@$headers) {
        $self->add_header_for_dataset($ds_id, {
            name => ($header // ''), sort => $sort++,
        });
    }

    return $ds_id;
}

sub get_dataset {
    my ($self, $dataset_id) = @_;
    my $sth = $self->dbh->prepare_cached('SELECT * FROM datasets WHERE id=?');
    $sth->execute($dataset_id);
    my $dataset = $sth->fetchrow_hashref();
    $sth->finish();
    $dataset->{data} = decode_json($dataset->{data});
    return $dataset;
}

sub get_datasets {
    my ($self, $login) = @_;
    my $sth = $self->dbh->prepare_cached(
        'SELECT datasets.* FROM datasets JOIN users ON user_id=users.id WHERE login=?'
    );
    $sth->execute($login);
    my $datasets = $sth->fetchall_arrayref({});
    $sth->finish();
    for my $ds (@{$datasets}) {
        $ds->{data} = decode_json($ds->{data});
    }
    return $datasets;
}

sub update_dataset {
    my ($self, $dataset_id, $args) = @_;
    $args->{name}  ||= '';
    $args->{notes} ||= '';
    my $sth = $self->dbh->prepare_cached('UPDATE datasets SET name=?, notes=? WHERE id=?');
    $sth->execute($args->{name}, $args->{notes}, $dataset_id);
    return $self->get_dataset($dataset_id);
}


sub add_header_for_dataset {
    my ($self, $ds_id, $args) = @_;
    my $sth = $self->dbh->prepare_cached(
        q{INSERT INTO columns (dataset_id, name, shortname, sort, accession_type, url_root) VALUES (?,?,?,?,?,?)}
    );

    (my $shortname = lc($args->{name} || 'nothing')) =~ s/[^0-9a-z_]/_/g;
    $shortname ||= 'empty';
    my @args = ($ds_id, $args->{name}, $shortname, $args->{sort}, '', '');
    warn "handleargs are: " . p(@args);
    $sth->execute(@args);
    return;
}


sub get_columns_for_dataset {
    my ($self, $ds_id) = @_;
    my $sth = $self->dbh->prepare_cached('SELECT * FROM columns WHERE dataset_id=?');
    $sth->execute($ds_id);
    return $sth->fetchall_arrayref({});
}

sub get_column {
    my ($self, $column_id) = @_;
    my $sth = $self->dbh->prepare_cached('SELECT * FROM columns WHERE id=?');
    $sth->execute($column_id);
    my $hr = $sth->fetchrow_hashref();
    $sth->finish();
    return $hr;
}


sub delete_column_for_dataset {
    my ($self, $column_id, $dataset_id) = @_;
    my $sth = $self->dbh->prepare_cached('DELETE FROM columns WHERE id=?');
    $sth->execute($column_id);
    return;
}

sub update_column_metadata {
    my ($self, $column_id, $args) = @_;

    my $sth = $self->dbh->prepare_cached(q{
        UPDATE columns
        SET is_accession=?, accession_type=?, is_url=?, url_root=?
        WHERE id=?
    });
    $sth->execute(
        ($args->{is_accession} // 0), ($args->{accession_type} // ''),
        ($args->{is_url} // 0), ($args->{url_root} // ''), $column_id
    );
    return;
}


sub new_page {
    my ($self, $ds_id, $args) = @_;
    my $sth = $self->dbh->prepare_cached(
        q{INSERT INTO pages (dataset_id, title, preamble, postamble) VALUES (?,?,?,?)}
    );
    $sth->execute($ds_id, '', '', '');
    return $self->dbh->last_insert_id(undef,undef,'pages','id');
}


sub get_page_for_dataset {
    my ($self, $ds_id) = @_;
    my $sth = $self->dbh->prepare_cached('SELECT * FROM pages WHERE dataset_id=?');
    $sth->execute($ds_id);
    my $hr = $sth->fetchrow_hashref();
    $sth->finish();
    return $hr;
}

sub get_page {
    my ($self, $page_id) = @_;
    my $sth = $self->dbh->prepare_cached('SELECT * FROM pages WHERE id=?');
    $sth->execute($page_id);
    my $hr = $sth->fetchrow_hashref();
    $sth->finish();
    return $hr;
}

sub update_page {
    my ($self, $page_id, $params) = @_;
    my $sth = $self->dbh->prepare_cached('UPDATE pages SET title=?, preamble=?, postamble=? WHERE id=?');
    my @args = map {$params->{'page.'.$_} // q{}} qw(title preamble postamble);
    $sth->execute(@args, $page_id);
    return $self->get_page($page_id);
}


sub get_page_columns {
    my ($self, $page_id) = @_;
    my $sth = $self->dbh->prepare_cached('SELECT * FROM page_columns WHERE page_id=?');
    $sth->execute($page_id);
    return $sth->fetchall_arrayref({});
}

sub add_page_column {
    my ($self, $page_id, $params) = @_;
    my $sth = $self->dbh->prepare_cached('INSERT INTO page_columns (page_id, title, template) VALUES (?,?,?)');
    my @args = map {$params->{'page_column.'.$_} // q{}} qw(title template);
    $sth->execute($page_id, @args);
    return $self->dbh->last_insert_id(undef,undef,'page_columns','id');
}

sub get_page_column {
    my ($self, $page_col_id) = @_;
    my $sth = $self->dbh->prepare_cached('SELECT * FROM page_columns WHERE id=?');
    $sth->execute($page_col_id);
    my $hr = $sth->fetchrow_hashref();
    $sth->finish();
    return $hr;
}

sub update_page_column {
    my ($self, $page_col_id, $params) = @_;
    my $sth = $self->dbh->prepare_cached('UPDATE page_columns SET title=?, template=? WHERE id=?');
    my @args = map {$params->{'page_column.'.$_} // q{}} qw(title template);
    $sth->execute(@args, $page_col_id);
    return $self->get_page_column($page_col_id);
}

sub delete_page_column {
    my ($self, $page_col_id) = @_;
    my $sth = $self->dbh->prepare_cached('DELETE FROM page_columns WHERE id=?');
    $sth->execute($page_col_id);
    return;
}

my %linkthings = (
    gene_name  => {label => '', links => [
        {
            value=>'gene',
            text=>'Entrez Gene',
            example=>'http://www.ncbi.nlm.nih.gov/gene/7094',
            prefix=>'http://www.ncbi.nlm.nih.gov/gene/',
            postfix=>'',
        },
        {
            value=>'uniprot',
            text=>'Uniprot',
            example=>'http://www.uniprot.org/uniprot/Q9Y490',
            prefix=>'http://www.uniprot.org/uniprot/',
            postfix=>'',
        },
        {
            value=>'cmkb',
            text=>'Cell Migration KnowledgeBase',
            example=>'http://cmckb.cellmigration.org/gene/?gene_name=TLN1',
            prefix=>'http://cmckb.cellmigration.org/gene/?gene_name=',
            postfix=>'',
        },
        {
            value=>'omim',
            text=>'OMIM',
            example=>'http://www.ncbi.nlm.nih.gov/omim/186745',
            prefix=>'http://www.ncbi.nlm.nih.gov/omim/',
            postfix=>'',
        },
        {
            value=>'pfam',
            text=>'PFAM',
            example=>'http://pfam.sanger.ac.uk/protein?acc=Q9Y490',
            prefix=>'http://pfam.sanger.ac.uk/protein?acc=',
            postfix=>'',
        },
        {
            value=>'addgene',
            text=>'AddGene',
            example=>'http://www.addgene.org/pgvec1?f=c&cmd=showgene&geneid=7094',
            prefix=>'http://www.addgene.org/pgvec1?f=c&cmd=showgene&geneid=',
            postfix=>'',
        },
        {
            value=>'kegg',
            text=>'KEGG',
            example=>'http://www.genome.jp/dbget-bin/www_bget?hsa:7094',
            prefix=>'http://www.genome.jp/dbget-bin/www_bget?hsa:',
            postfix=>'',
        },
    ],},
    flybase_id => {label => '', links => [
        {
            value => 'flybase',
            text => 'FlyBase',
            example => 'http://flybase.bio.indiana.edu/.bin/fbidq.html?FBgn0025725',
            prefix => 'http://flybase.bio.indiana.edu/.bin/fbidq.html?',
            postfix=>'',
        },
    ],},
    unigene_id => {
        label => '',
        links => [
        {
            value=>'unigene',
            text=>'UniGene',
            example=>'http://www.ncbi.nlm.nih.gov/unigene/686173',
            prefix=>'http://www.ncbi.nlm.nih.gov/unigene/',
            postfix=>'',
        },
    ],},
);

sub get_linksites {
    my ($self) = @_;

    my %new_struct;
    for my $t (values %linkthings) {
        for my $l (@{$t->{links}}) {
            $new_struct{$l->{value}} = $l;
        }
    }

    return \%new_struct;
}


sub get_linksets_for_dataset {
    my ($self, $ds_id) = @_;

    my @linksets;
    for my $col (@{$self->get_columns_for_dataset($ds_id)}) {
        next unless $col->{is_accession};
        $col->{links} = $self->get_linkset_for_column($col);
        push @linksets, $col;
    }
    return \@linksets;
}

sub get_linkset_for_column {
    my ($self, $col) = @_;

    my @links;
    if ($col->{is_accession}) {
        @links = @{$linkthings{$col->{accession_type}}->{links}}
    }
    elsif ($col->{is_url}) {
        @links = 'something else?';
    }

    return \@links;
}



sub accession_types {
    my ($self) = @_;
    return [
        { group_label => 'NCBI', types => [
            map {{field => $_->[0], label => $_->[1],}} (
                ['gene_id',    'Gene ID',   ],
                ['gene_name',  'Gene Name', ],
                ['refseq_id',  'RefSeq ID', ],
                ['protein_id', 'Protein ID',],
                ['unigene_id', 'UniGene ID',],
                ['pubmed_id',  'PubMed ID', ],
            )
        ], },
        { group_label => 'Uniprot', types => [
            map {{field => $_->[0], label => $_->[1],}} (
                ['uniprot_id', 'Uniprot ID'],
            )
        ], },
        { group_label => 'CritterBases', types => [
            map {{field => $_->[0], label => $_->[1],}} (
                ['flybase_id',  'FlyBase ID',  ],
                ['wormbase_id', 'WormBase ID', ],
            )
        ], },
    ];
}

sub clear {
    my ($self) = @_;
    $self->dbh->do('DROP TABLE IF EXISTS users;');
    $self->dbh->do('DROP TABLE IF EXISTS datasets;');
    $self->dbh->do('DROP TABLE IF EXISTS columns;');
    $self->dbh->do('DROP TABLE IF EXISTS pages;');
    $self->dbh->do('DROP TABLE IF EXISTS page_columns;');
    return $self;
}
sub load_schema {
    my ($self) = @_;
    $self->dbh->do(<<'USERS');
CREATE TABLE IF NOT EXISTS users (
  id    integer PRIMARY KEY AUTOINCREMENT,
  login text NOT NULL UNIQUE,
  name  text NOT NULL
);
USERS

    $self->dbh->do(<<'DATASET');
CREATE TABLE IF NOT EXISTS datasets (
  id       integer PRIMARY KEY AUTOINCREMENT,
  user_id  integer NOT NULL REFERENCES users (id),
  name     text NOT NULL,
  notes    text NOT NULL,
  original text NOT NULL,
  data     text NOT NULL
);
DATASET

    $self->dbh->do(<<'COLUMNS');
CREATE TABLE IF NOT EXISTS columns (
  id             integer PRIMARY KEY AUTOINCREMENT,
  dataset_id     integer NOT NULL REFERENCES datasets (id),
  name           text NOT NULL,
  shortname      text NOT NULL,
  sort           integer NOT NULL,
  is_accession   integer NOT NULL DEFAULT 0,
  accession_type text NOT NULL,
  is_url         integer NOT NULL DEFAULT 0,
  url_root       text NOT NULL
);
COLUMNS


    $self->dbh->do(<<'PAGES');
CREATE TABLE IF NOT EXISTS pages (
  id         integer PRIMARY KEY AUTOINCREMENT,
  dataset_id integer NOT NULL REFERENCES datasets (id),
  title      text NOT NULL,
  preamble   text NOT NULL,
  postamble  text NOT NULL
);
PAGES

    $self->dbh->do(<<'PAGE_COLUMNS');
CREATE TABLE IF NOT EXISTS page_columns (
  id       integer PRIMARY KEY AUTOINCREMENT,
  page_id  integer NOT NULL REFERENCES pages (id),
  title    text NOT NULL,
  template text NOT NULL
);
PAGE_COLUMNS

    return $self;
}
sub load_data {
    my ($self) = @_;
    $self->dbh->do(<<'SQL');
INSERT INTO users (login, name) VALUES ('fge7z','Fitz Elliott');
SQL
    return $self;

}

__PACKAGE__->meta->make_immutable;

1;
__END__
