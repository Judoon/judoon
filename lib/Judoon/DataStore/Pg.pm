package Judoon::DataStore::Pg;

use Moo;

use Moo;
use MooX::Types::MooseLike::Base qw(Str ArrayRef);

use Judoon::Web;

=head1 ATTRIBUTES

=cut

has my_dsn => (is => 'lazy', isa => ArrayRef, required => 1,);


# have to apply base role after attributes are defined to meet
# requires criteria
with 'Judoon::DataStore::Role::Base';


=head1 METHODS

=cut

sub exists {
    my ($self) = @_;
    my $sth = $self->dbh->prepare_cached('SELECT schema_name FROM information_schema.schemata WHERE schema_name = ?');
    $sth->execute($self->owner);
    my $found = $sth->fetchrow_hashref();
    $sth->finish;
    return $found;
}

sub init {
    my ($self) = @_;
    $self->dbh->do('CREATE SCHEMA ' . $self->owner);
}

sub sqlt_producer_class { return 'PostgreSQL'; }

sub sqlt_producer_args { return {no_transaction => 1,}; }

1;
__END__
