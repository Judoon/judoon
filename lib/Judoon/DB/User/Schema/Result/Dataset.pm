use utf8;
package Judoon::DB::User::Schema::Result::Dataset;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

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

=head2 data

  data_type: 'text'
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
  "data",
  { data_type => "text", is_nullable => 0 },
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


# Created by DBIx::Class::Schema::Loader v0.07025 @ 2012-07-12 12:56:24
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:JrQ45OumPMbWAMAGmA8KHg

__PACKAGE__->load_components('InflateColumn::Serializer');
__PACKAGE__->add_column('+data' => { serializer_class => 'JSON', });

use DateTime;
use Judoon::Error;
use Judoon::Tmpl::Factory;
use Spreadsheet::WriteExcel ();

with qw(Judoon::DB::User::Schema::Role::Result::HasPermissions);
__PACKAGE__->register_permissions;

=pod

=encoding utf8

=cut


has dummy => (is => 'ro', default => sub {1},);

sub BUILDARGS {
    my ($class, $args) = @_;

    if (exists $args->{spreadsheet}) {
        my $spreadsheet = delete $args->{spreadsheet};
        die q{'spreadsheet' argument to Result::Dataset must be a Judoon::Spreadsheet'}
            unless (ref $spreadsheet eq 'Judoon::Spreadsheet');
        $args->{name} //= $spreadsheet->worksheet_name;
        $args->{original} //= q{};
        $args->{data}     //= $spreadsheet->data;
        $args->{notes}    //= q{};
        if (not exists $args->{ds_columns}) {
            my @cols;
            my $sort = 1;
            for my $header (@{$spreadsheet->headers}) {
                push @cols, {
                    name => ($header // ''), sort => $sort++,
                    accession_type => q{},   url_root => q{},
                };
            }

            $args->{ds_columns} = \@cols;
        }
    }

    return $args;
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

    for my $ds_column ($self->ds_columns) {
        my $page_column = $page->create_related('page_columns', {
            title    => $ds_column->name,
            template => '',
        });
        $page_column->set_template(new_variable_node({name => $ds_column->shortname}));
        $page_column->update;
    }

    return $page;
}

=head2 nbr_columns

Number of columns in this dataset.

=cut

sub nbr_columns {
    my ($self) = @_;
    my $data = $self->data;
    return scalar @{$data->[0]};
}


=head2 nbr_rows

Number of rows in this dataset.

=cut

sub nbr_rows {
    my ($self) = @_;
    my $data = $self->data;
    return scalar @$data;
}


=head2 data_table

Returns an arrayref of arrayref of the dataset's data with the header
columns.

=cut

sub data_table {
    my ($self) = @_;
    return [[map {$_->name} $self->ds_columns], @{$self->data}];
}


=head2 as_raw

Return data as a tab-delimited file

=cut

sub as_raw {
    my ($self) = @_;

    my $raw_file = q{};
    for my $row (@{$self->data_table}) {
        $raw_file .= join "\t", @$row;
        $raw_file .= "\n";
    }

    return $raw_file;
}


=head2 as_excel

Return data as an Excel spreadsheet

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


=head2 C<B<delete_data_columns( @column_numbers )>>

Deletes the given column numbers from the dataset. Is 1-indexed.

=cut

sub delete_data_columns {
    my ($self, @col_nums) = @_;

    my $nbr_cols = $self->nbr_columns;
    my $errmsg = (grep {!defined || $_ !~ m/^\d+$/} @col_nums) ? 'received input that was not a positive integer'
               : (grep {$_ == 0}        @col_nums) ? 'received a column number of 0; columns are 1-indexed'
               : (grep {$_ > $nbr_cols} @col_nums) ? 'received a number larger than the number of columns'
               :                                    q{};
    Judoon::Error->throw({recoverable => 0, message => "delete_data_columns $errmsg"})
          if ($errmsg);

    # reverse sort, so deleting early index doesn't throw off later count
    my @ordered_nums = sort {$b <=> $a} @col_nums;
    my $data = $self->data;
    for my $row (@$data) {
        for my $colnum (@ordered_nums) {
            splice @$row, $colnum-1, 1;
        }
    }
    $self->data($data);
    $self->update;
}


1;
