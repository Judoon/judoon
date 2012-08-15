package Judoon::DataStore::Role::Base;

use Moo::Role;

use MooX::Types::MooseLike::Base qw(Str);

has owner => (is => 'ro', isa => Str, required => 1,);

requires 'exists';
requires 'init';


before 'init' => sub {
    my ($self) = @_;
    die 'datastore already exists' if ($self->exists);
    return;
};


1;
__END__
