package Judoon::DataStore::SQLite;

use Moo;

with 'Judoon::DataStore::Role::Base';

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


=head1 METHODS

=cut

sub exists { return -d $_[0]->owner_dir; }

sub init {
    my ($self) = @_;
    $self->owner_dir->mkpath;
}


1;
__END__
