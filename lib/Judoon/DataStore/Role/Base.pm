package Judoon::DataStore::Role::Base;

use Moo::Role;
use MooX::Types::MooseLike::Base qw(Str HashRef);

use DBI;
use Judoon::DB::DataStore::Schema;
use Path::Class::Dir;
use SQL::Translator;


=head1 ATTRIBUTES

=cut

# datastore owner, helps to namespace, should have record in
# users table of master database.
has owner => (is => 'ro', isa => Str, required => 1,);


# the template schema, used for initializing a new user's schema
has template_schema_class => (is => 'lazy', isa => Str);
sub _build_template_schema_class {
    my ($self) = @_;
    return 'Judoon::DB::DataStore::Schema';
}
has template_schema => (is => 'lazy',); # isa => DBIx::Class::Schema
sub _build_template_schema {
    my ($self) = @_;
    return $self->template_schema_class->connect(@{$self->my_dsn});
}

has dbh => (is => 'lazy');
sub _build_dbh {
    my ($self) = @_;
    return DBI->connect(@{$self->my_dsn});
}


has sqlt_producer_args => (is => 'lazy', isa => HashRef,);
sub _build_sqlt_producer_args { return {}; }



=head1 METHODS

=cut

requires 'exists';
requires 'init';
requires 'my_dsn';
requires 'db_name';
requires 'sqlt_producer_class';

before 'init' => sub {
    my ($self) = @_;
    die 'datastore already exists' if ($self->exists);
    return;
};


sub create_db {
    my ($self) = @_;
    $self->template_schema->deploy;
}


sub add_dataset {
    my ($self, $filename) = @_;

    use Judoon::Spreadsheet;
    my $spreadsheet = Judoon::Spreadsheet->new(filename => $filename);

    my $sqlt = SQL::Translator->new(
        parser_args => {
            scan_fields     => 0,
            spreadsheet_ref => $spreadsheet->spreadsheet,
        },

        producer_args => { %{$self->sqlt_producer_args}, },
    );
    my $sql = $sqlt->translate(
        from => 'Spreadsheet',
        to   => $self->sqlt_producer_class,
    ) or die $sqlt->error;


    $self->dbh->do($sql);
}



# sub add_dataset {
#     my ($self, $dataset) = @_;
#     die '$dataset is not a Dataset object'
#         unless (ref $dataset eq m/Judoon::DB::User::Result::Dataset/);
# 
#     my $table_name = $self->gen_table_name($dataset->name);
# }

sub gen_table_name {
    my ($self, $table_name) = @_;

    $table_name =~ s/[^a-z_0-9]+/_/g;
    return $table_name unless ($self->table_exists($table_name));

    my $new_name = first {not $self->table_exists($_)}
        map { "${table_name}_${_}" } (1..10);
    return $new_name if ($new_name);

    $new_name = $table_name . '_' . time();
    die "Unable to find suitable name for table: $table_name"
        if ($self->table_exists($new_name));
    return $new_name;
}

sub table_exists {
    my ($self, $name) = @_;

    my $dbh = $self->template_schema->storage->dbh;
    my $sth = $dbh->table_info(undef, '%', $name, "TABLE");
    my $ary = $sth->fetchall_arrayref();
    return @$ary;
}

1;
__END__
