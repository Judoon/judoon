package Judoon::Schema::Result::Dataset;

=pod

=encoding utf8

=head1 NAME

Judoon::Schema::Result::Dataset

=cut

use Moo;
extends 'Judoon::Schema::Result';


use Data::UUID;
use DateTime;
use Judoon::Error::Devel::Arguments;
use Judoon::Error::Devel::Impossible;
use Judoon::Tmpl;
use List::AllUtils qw(each_arrayref);
use Spreadsheet::WriteExcel ();


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
    id => {
        data_type         => "integer",
        is_auto_increment => 1,
        is_nullable       => 0,
    },
    user_id => {
        data_type      => "integer",
        is_foreign_key => 1,
        is_nullable    => 0,
    },
    name => {
        data_type   => "text",
        is_nullable => 0,
    },
    notes => {
        data_type   => "text",
        is_nullable => 0,
    },
    original => {
        data_type   => "text",
        is_nullable => 0,
    },
    tablename => {
        data_type   => "text",
        is_nullable => 0,
    },
    nbr_rows => {
        data_type   => "integer",
        is_nullable => 0,
        is_numeric  => 1,
    },
    nbr_columns => {
        data_type   => "integer",
        is_nullable => 0,
        is_numeric  => 1,
    },
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

Related object: L<Judoon::Schema::Result::DatasetColumn>

=cut

__PACKAGE__->has_many(
    ds_columns => "::DatasetColumn",
    { "foreign.dataset_id" => "self.id" },
    { cascade_copy => 0, cascade_delete => 1 },
);

=head2 pages

Type: has_many

Related object: L<Judoon::Schema::Result::Page>

=cut

__PACKAGE__->has_many(
    pages => "::Page",
    { "foreign.dataset_id" => "self.id" },
    { cascade_copy => 0, cascade_delete => 1 },
);

=head2 user

Type: belongs_to

Related object: L<Judoon::Schema::Result::User>

=cut

__PACKAGE__->belongs_to(
    user => "::User",
    { id => "user_id" },
    { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


=head1 EXTRA COMPONENTS

=head2 ::Role::Result::HasPermissions

Add C<permission> column / methods to C<Dataset>.

=head2 ::Role::Result::HasTimestamps

Add <created> and <modified> columns to C<Dataset>.

=cut

with qw(
    Judoon::Schema::Role::Result::HasPermissions
    Judoon::Schema::Role::Result::HasTimestamps
);
__PACKAGE__->register_permissions;
__PACKAGE__->register_timestamps;


=head1 METHODS

=head2 delete()

Delete datastore table after deleteing object

=cut

sub delete {
    my ($self) = @_;
    $self->next::method(@_);
    $self->_delete_datastore();
    return;
}


=head2 ds_columns_ordered()

Get DatasetColumns in sorted order

=cut

sub ds_columns_ordered {
    my ($self) = @_;
    return $self->ds_columns_rs->search_rs({},{order_by => {-asc => 'sort'}});
}


=head2 pages_ordered()

Get related Pages in sorted order

=cut

sub pages_ordered {
    my ($self) = @_;
    return $self->pages_rs->search_rs({}, {order_by => {-asc => 'created'}});
}


=head2 import_from_spreadsheet( $spreadsheet )

Update a new C<Dataset> from a C<Judoon::Spreadsheet> object.  Calling this
will create a new table in the Datastore and store the meta-information in the
C<Dataset> and C<DatasetColumns>.

=cut

sub import_from_spreadsheet {
    my ($self, $spreadsheet) = @_;

    Judoon::Error::Devel::Arguments->throw({
        message  => q{'spreadsheet' argument to Result::Dataset must be a Judoon::Spreadsheet'},
        expected => q{->isa('Judoon::Spreadsheet')},
        got      => q{->isa('} . ref($spreadsheet) . q{')},
    }) unless (ref $spreadsheet eq 'Judoon::Spreadsheet');

    my $table_name = $self->_store_data($spreadsheet);

    $self->name($spreadsheet->name);
    $self->tablename($table_name);
    $self->nbr_rows($spreadsheet->nbr_rows);
    $self->nbr_columns($spreadsheet->nbr_columns);
    $self->notes(q{});
    $self->original(q{});
    $self->update;

    my $sort = 1;
    for my $field (@{ $spreadsheet->fields }) {
        $self->create_related('ds_columns', {
            name => $field->{name}, shortname => $field->{shortname},
            sort => $sort++, data_type => $field->{type},
        });
    }

    return $self;
}


=head2 create_basic_page()

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
            template => Judoon::Tmpl->new_from_data([
                {type => 'variable', name => $ds_column->shortname,}
            ]),
            sort     => $i++,
        });
    }

    return $page;
}


=head2 data_table( $args )

Returns an arrayref of arrayref of the dataset's data with the header
columns. If C<< $args->{shortname} >> is true, use the column shortnames
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


=head2 as_raw( $args )

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


=head2 as_excel

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

=head2 data() / _build_data()

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


has sample_data => (is => 'lazy',);
sub _build_sample_data {
    my ($self) = @_;

    my @sample_data;
    for my $idx (0..$self->nbr_columns-1) {
      ROW_SEARCH:
        for my $row (@{$self->data}) {
            if (defined($row->[$idx]) && $row->[$idx] =~ m/\S/) {
                push @sample_data, $row->[$idx];
                last ROW_SEARCH;
            }
        }
    }

    my %sample_data;
    @sample_data{map {$_->shortname} $self->ds_columns_ordered->all}
        = @sample_data;
    return \%sample_data;
}



=head2 _store_data( $spreadsheet )

This private method creates the new table for the data in the
Datastore.  It also checks for table name collisions and changes the
name accordingly.  After creating the table, it inserts the
data. Returns the new table name.

=cut

sub _store_data {
    my ($self, $spreadsheet) = @_;

    Judoon::Error::Devel::Arguments->throw({
        message  => q{'spreadsheet' argument to Result::Dataset must be a Judoon::Spreadsheet'},
        expected => q{->isa('Judoon::Spreadsheet')},
        got      => q{->isa('} . ref($spreadsheet) . q{')},
    }) unless (ref $spreadsheet eq 'Judoon::Spreadsheet');

    my $schema     = $self->schema_name;
    my $table_name = $self->_gen_table_name( $spreadsheet->name );
    my @fields     = @{ $spreadsheet->fields };
    my $sql        = qq{CREATE TABLE "$schema"."$table_name" (\n}
        . join(",\n", map { qq|"$_->{shortname}" text| } @fields)
        . ')';

    # create table
    my $dbic_storage = $self->result_source->storage;
    $dbic_storage->dbh_do(
        sub {
            my ($storage, $dbh) = @_;
            $dbh->do($sql);
        },
    );

    # populate table
    my $field_list = join ', ', map {$_->{shortname}} @fields;
    my $join_list  = join ', ', (('?') x @fields);
    $dbic_storage->dbh_do(
        sub {
            my ($storage, $dbh) = @_;
            my $sth_insert = $dbh->prepare_cached(
                "INSERT INTO $schema.$table_name ($field_list) VALUES ($join_list)"
            );
            $sth_insert->execute(@$_) for (@{$spreadsheet->data});
        },
    );

    return $table_name;
}


=head2 _delete_datastore()


=cut

sub _delete_datastore {
    my ($self) = @_;

    my $dbic_storage = $self->result_source->storage;
    $dbic_storage->dbh_do(
        sub {
            my ($storage, $dbh) = @_;
            my ($schema_name, $table_name) = ($self->schema_name, $self->tablename);
            $dbh->do(qq{DROP TABLE $schema_name.$table_name});
        },
    );
    return;
}


=head2 _gen_table_name( $table_name )

Private method to generate a new table name.  This method trys a
couple different techniques, but will die if it's unable to find a
unique name.

=cut

sub _gen_table_name {
    my ($self, $table_name) = @_;

    $table_name = lc($table_name);
    $table_name =~ s/[^a-z_0-9]+/_/gi;
    return $table_name unless ($self->_table_exists($table_name));

    my $new_name = List::AllUtils::first {not $self->_table_exists($_)}
        map { "${table_name}_" . sprintf('%02d', $_) } (1..99);
    return $new_name if ($new_name);

    $new_name = $table_name . '_' . time();
    return $new_name unless ($self->_table_exists($new_name));

    # if this doesn't work, something is seriously wrong
    $new_name = $table_name . '_' . Data::UUID->new->create_str();
    $new_name =~ s/-/_/g;
    Judoon::Error::Devel::Impossible->throw({
        message => "Unable to find suitable name for table: $table_name",
    })  if ($self->_table_exists($new_name));
    return $new_name;
}


=head2 _table_exists( $table_name )

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


=head2 schema_name() / _build_schema_name()

Return schema name, which changes based on database engine.  For
SQLite, the schema name is always 'data'.  For Pg, it's based on the
name of the user.

=cut

has schema_name => (is => 'lazy',);
sub _build_schema_name {
    my ($self) = @_;
    return $self->user->schema_name;
}


1;
