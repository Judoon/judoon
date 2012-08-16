package Judoon::DataStore::SQLite;

use Moo;
use MooX::Types::MooseLike::Base qw(Str ArrayRef);


use Path::Class::Dir ();

=head1 ATTRIBUTES

=cut

has storage_dir => (is => 'lazy',); # isa => Str,);
sub _build_storage_dir {
    my ($self) = @_;
    return Path::Class::Dir->new(
        $ENV{JUDOON_DATASTORE_DATA_DIR} // 'share/dbs'
    );
}

has owner_dir => (is => 'lazy',); # isa => Str,);
sub _build_owner_dir {
    my ($self) = @_;
    return $self->storage_dir->subdir($self->owner);
}

has my_dsn => (is => 'lazy', isa => ArrayRef);
sub _build_my_dsn {
    my ($self) = @_;
    return [
        'dbi:SQLite:dbname=' . $self->db_path
    ];
}

has db_path => (is => 'lazy',); # isa => Path::Class::File
sub _build_db_path {
    my ($self) = @_;
    return $self->owner_dir->file($self->db_name);
}

has db_name => (is => 'ro', isa => Str, default => sub {'datastore.db'},);


# have to apply base role after attributes are defined to meet
# requires criteria
with 'Judoon::DataStore::Role::Base';


=head1 METHODS

=cut

sub exists { return -d $_[0]->owner_dir; }

sub init {
    my ($self) = @_;
    $self->owner_dir->mkpath;
    $self->deploy_schema();
}


1;
__END__
