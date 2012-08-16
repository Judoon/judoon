package Judoon::DB::DataStore::Schema;

our $VERSION = 1;

use Moo;
extends 'DBIx::Class::Schema';


__PACKAGE__->load_namespaces;

1;
__END__
