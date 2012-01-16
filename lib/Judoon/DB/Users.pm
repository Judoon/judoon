package Judoon::DB::Users;

use version; our $VERSION = '0.0.1';
use strict;
use warnings;
use autodie;
use open qw( :encoding(UTF-8) :std );
use feature ':5.14';

use Moose;
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
    return $self->dbh->last_insert_id(undef,undef,'datasets','id');
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



sub reinit { return $_[0]->clear->init; }
sub init   { return $_[0]->load_schema->load_data; }
sub clear {
    my ($self) = @_;
    $self->dbh->do('DROP TABLE users;');
    $self->dbh->do('DROP TABLE datasets;');
    return $self;
}
sub load_schema {
    my ($self) = @_;
    $self->dbh->do(<<'USERS');
CREATE TABLE users (
  id    integer PRIMARY KEY AUTOINCREMENT,
  login text NOT NULL UNIQUE,
  name  text NOT NULL
);
USERS

    $self->dbh->do(<<'DATASET');
CREATE TABLE datasets (
  id       integer PRIMARY KEY AUTOINCREMENT,
  user_id  integer NOT NULL REFERENCES users (id),
  name     text NOT NULL,
  notes    text NOT NULL,
  original text NOT NULL,
  data     text NOT NULL
);
DATASET
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
