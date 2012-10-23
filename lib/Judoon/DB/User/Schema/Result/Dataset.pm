use utf8;
package Judoon::DB::User::Schema::Result::Dataset;

=pod

=encoding utf8

=head1 NAME

Judoon::DB::User::Schema::Result::Dataset

=cut

use Moo;
extends 'DBIx::Class::Core';

=head1 TABLE: C<datasets>

=cut

__PACKAGE__->table("datasets");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 user_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 name

  data_type: 'text'
  is_nullable: 0

=head2 notes

  data_type: 'text'
  is_nullable: 0

=head2 original

  data_type: 'text'
  is_nullable: 0

=head2 tablename

  data_type: 'text'
  is_nullable: 0

=head2 nbr_rows

  data_type: 'integer'
  is_nullable: 0

=head2 nbr_columns

  data_type: 'integer'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "user_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "name",
  { data_type => "text", is_nullable => 0 },
  "notes",
  { data_type => "text", is_nullable => 0 },
  "original",
  { data_type => "text", is_nullable => 0 },
  "tablename",
  { data_type => "text", is_nullable => 0 },
  "nbr_rows",
  { data_type => "integer", is_nullable => 0 },
  "nbr_columns",
  { data_type => "integer", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 ds_columns

Type: has_many

Related object: L<Judoon::DB::User::Schema::Result::DatasetColumn>

=cut

__PACKAGE__->has_many(
  "ds_columns",
  "Judoon::DB::User::Schema::Result::DatasetColumn",
  { "foreign.dataset_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 1 },
);

=head2 pages

Type: has_many

Related object: L<Judoon::DB::User::Schema::Result::Page>

=cut

__PACKAGE__->has_many(
  "pages",
  "Judoon::DB::User::Schema::Result::Page",
  { "foreign.dataset_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 1 },
);

=head2 user

Type: belongs_to

Related object: L<Judoon::DB::User::Schema::Result::User>

=cut

__PACKAGE__->belongs_to(
  "user",
  "Judoon::DB::User::Schema::Result::User",
  { id => "user_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


use DateTime;
use Judoon::Error;
use Judoon::Tmpl;
use Judoon::Tmpl::Factory qw(new_variable_node);
use List::AllUtils qw(each_arrayref);
use Spreadsheet::WriteExcel ();
use SQL::Translator;

# add permission column / methods to Dataset
with qw(Judoon::DB::User::Schema::Role::Result::HasPermissions);
__PACKAGE__->register_permissions;


=head1 METHODS


=head2 B<C<ds_columns_ordered>>

Get DatasetColumns in sorted order

=cut

sub ds_columns_ordered {
    my ($self) = @_;
    return $self->ds_columns_rs->search_rs({},{order_by => {-asc => 'sort'}});
}


=head2 B<C<import_from_spreadsheet>>

Update a new C<Dataset> from a C<Judoon::Spreadsheet> object.  Calling this
will create a new table in the Datastore and store the meta-information in the
C<Dataset> and C<DatasetColumns>.

=cut

sub import_from_spreadsheet {
    my ($self, $spreadsheet) = @_;
    die q{'spreadsheet' argument to Result::Dataset must be a Judoon::Spreadsheet'}
        unless (ref $spreadsheet eq 'Judoon::Spreadsheet');

    my $sqlt_table = $self->_store_data($spreadsheet);
    $self->name($spreadsheet->worksheet_name);
    my $schema_name = $self->schema_name;
    (my $tablename = $sqlt_table->name) =~ s/^$schema_name\.//; # get rid of schema
    $self->tablename($tablename);
    $self->nbr_rows($spreadsheet->nbr_rows);
    $self->nbr_columns($spreadsheet->nbr_columns);
    $self->notes(q{});
    $self->original(q{});
    $self->update;

    my $sort = 1;
    my $it = each_arrayref $spreadsheet->headers, [$sqlt_table->get_fields];
    while (my ($header, $sqlt_field) = $it->()) {
        $self->create_related('ds_columns', {
            name => ($header // ''), shortname => $sqlt_field->name,
            sort => $sort++, accession_type => q{},   url_root => q{},
        });
    }

    return $self;
}


=head2 B<C<create_basic_page()>>

Turn a dataset into a simple page with a one-to-one mapping between
data columns and page columns.

=cut

sub create_basic_page {
    my ($self) = @_;

    my $DEFAULT_PREAMBLE = <<'EOS';
<p>This is a standard table.</p>
<p>Edit this by logging into your account and selecting 'edit page'.</p>
EOS
    my $DEFAULT_POSTAMBLE = <<'EOS';
Created with Judoon on 
EOS
    $DEFAULT_POSTAMBLE .= DateTime->now();

    my $page = $self->create_related('pages', {
        title     => $self->name,
        preamble  => $DEFAULT_PREAMBLE,
        postamble => $DEFAULT_POSTAMBLE,
    });

    my $i = 1;
    for my $ds_column ($self->ds_columns_ordered->all) {
        my $page_column = $page->create_related('page_columns', {
            title    => $ds_column->name,
            template => Judoon::Tmpl->new({
                nodes => [new_variable_node({name => $ds_column->shortname})],
            }),
            sort     => $i++,
        });
    }

    return $page;
}


=head2 B<C<data_table( $args )>>

Returns an arrayref of arrayref of the dataset's data with the header
columns. If C<$args->{shortname}> is true, use the column shortnames
in the header instead of the original names

=cut

sub data_table {
    my ($self, $args) = @_;
    return [
        [map {$args->{shortname} ? $_->shortname : $_->name}
             sort {$a->sort <=> $b->sort} $self->ds_columns_ordered->all],
        @{$self->data},
    ];
}


=head2 B<C<as_raw( $args )>>

Return data as a tab-delimited string. Passes C<$args> to C<L</data_table>>.

=cut

sub as_raw {
    my ($self, $args) = @_;

    my $raw_file = q{};
    for my $row (@{$self->data_table($args)}) {
        $raw_file .= join "\t", @$row;
        $raw_file .= "\n";
    }

    return $raw_file;
}


=head2 B<C<as_excel>>

Return data as an Excel spreadsheet.

=cut

sub as_excel {
    my ($self) = @_;

    my $output;
    open my $fh, '>', \$output;
    my $workbook = Spreadsheet::WriteExcel->new($fh);
    $workbook->compatibility_mode();
    my $worksheet = $workbook->add_worksheet();
    $worksheet->write_col('A1', $self->data_table);
    $workbook->close();
    return $output;
}



=head1 DATASTORE

The following methods create and retreive the actual dataset data,
which is stored in a different schema and table.

=head2 B<C<data / _build_data>>

Accessor for getting at the data stored in the Datastore.

=cut

has data => (is => 'lazy',);
sub _build_data {
    my ($self) = @_;

    my @columns = map {$_->shortname} sort {$a->sort <=> $b->sort}
        $self->ds_columns_ordered->all;
    my $select = join ', ', @columns;

    my $table = $self->schema_name . '.' . $self->tablename;
    return $self->result_source->storage->dbh_do(
        sub {
            my ($storage, $dbh) = @_;
            my $sth = $dbh->prepare("SELECT $select FROM $table");
            $sth->execute;
            return $sth->fetchall_arrayref();
        },
    );
}


=head2 B<C< _store_data( $spreadsheet ) >>

This private method actually creates the new table for the data in the
Datastore.  It passes the spreadsheet to L<SQL::Translator> to get the
SQL for creating the table.  It also checks for table name collisions
and changes the name accordingly.  After creating the table, it
inserts the data. Returns the new table name.

=cut

sub _store_data {
    my ($self, $spreadsheet) = @_;
    die 'arg must be a Judoon::Spreadsheet'
        unless (ref $spreadsheet eq 'Judoon::Spreadsheet');

    my $sqlt = SQL::Translator->new(
        parser_args => {
            scan_fields     => 0,
            spreadsheet_ref => $spreadsheet->spreadsheet,
        },

        producer_args => { no_transaction => 1, },

        filters => [
            sub { $self->_check_table_name(shift); },
            ['Names', {fields => 'lc',} ],
        ],
    );

    my $dbic_storage = $self->result_source->storage;

    # translate to sql
    my $sql = $sqlt->translate(
        from => 'Spreadsheet',
        to   => $dbic_storage->sqlt_type,
    ) or die $sqlt->error;

    # create table
    $dbic_storage->dbh_do(
        sub {
            my ($storage, $dbh) = @_;
            $dbh->do($sql);
        },
    );

    # populate table
    my ($table)    = $sqlt->schema->get_tables;
    my $table_name = $table->name;
    my @fields     = map {$_->name} $table->get_fields;
    my $field_list = join ', ', @fields;
    my $join_list  = join ', ', (('?') x @fields);

    $dbic_storage->dbh_do(
        sub {
            my ($storage, $dbh) = @_;
            my $sth_insert = $dbh->prepare_cached(
                "INSERT INTO $table_name ($field_list) VALUES ($join_list)"
            );
            $sth_insert->execute(@$_) for (@{$spreadsheet->data});
        },
    );

    return $table;
}


=head2 B<C< _check_table_name >>

Private method passed to the L<SQL::Translator> filter to create a
unique table name.

=cut

sub _check_table_name {
    my ($self, $sqlt_schema) = @_;

    my ($table)    = $sqlt_schema->get_tables();
    my $table_name = $self->_gen_table_name($table->name);

    if ($self->result_source->storage->sqlt_type eq 'SQLite') {
        $table_name = '[' . $table_name . ']';
    }

    $table->name($self->schema_name . '.' . $table_name);
    return;
}


=head2 B<C< _gen_table_name >>

Private method to generate a new table name.  This method trys a
couple different techniques, but will die if it's unable to find a
unique name.

=cut

sub _gen_table_name {
    my ($self, $table_name) = @_;

    $table_name = lc($table_name);
    $table_name =~ s/[^a-z_0-9]+/_/gi;
    if ($self->result_source->storage->sqlt_type eq 'SQLite') {
        $table_name = $self->user->username . '@' . $table_name;
    }
    return $table_name unless ($self->_table_exists($table_name));

    my $new_name = List::AllUtils::first {not $self->_table_exists($_)}
        map { "${table_name}_${_}" } (1..10);
    return $new_name if ($new_name);

    $new_name = $table_name . '_' . time();
    die "Unable to find suitable name for table: $table_name"
        if ($self->_table_exists($new_name));
    return $new_name;
}


=head2 B<C< _table_exists >>

Private method to test whether a particular table name is already in
use.

=cut

sub _table_exists {
    my ($self, $name) = @_;
    return $self->result_source->storage->dbh_do(
        sub {
            my ($storage, $dbh) = @_;
            my $sth = $dbh->table_info(undef, $self->schema_name, $name, "TABLE");
            my $ary = $sth->fetchall_arrayref();
            return @$ary;
        },
    );
}


has schema_name => (is => 'lazy',);
sub _build_schema_name {
    my ($self) = @_;
    return $self->result_source->storage->sqlt_type eq 'SQLite'
        ? 'data' : $self->user->username;
}

1;
