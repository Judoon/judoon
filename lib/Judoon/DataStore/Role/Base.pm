package Judoon::DataStore::Role::Base;

use Moo::Role;
use MooX::Types::MooseLike::Base qw(Str);

use Judoon::DB::DataStore::Schema;

has owner => (is => 'ro', isa => Str, required => 1,);

has schema_class => (is => 'lazy', isa => Str);
sub _build_schema_class {
    my ($self) = @_;
    return 'Judoon::DB::DataStore::Schema';
}

has schema => (is => 'lazy',); # isa => DBIx::Class::Schema
sub _build_schema {
    my ($self) = @_;
    return $self->schema_class->connect(@{$self->my_dsn});
}

requires 'exists';
requires 'init';
requires 'my_dsn';
requires 'db_name';

before 'init' => sub {
    my ($self) = @_;
    die 'datastore already exists' if ($self->exists);
    return;
};


sub deploy_schema {
    my ($self) = @_;
    $self->schema->deploy;
}


1;
__END__
