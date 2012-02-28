package Judoon::DB::User;

our $VERSION = '0.0.1';

use Moose;
use namespace::autoclean;

use Method::Signatures;


has schema => (
    is         => 'ro',
    isa        => 'Judoon::DB::User::Schema',
    lazy_build => 1,
);

sub _build_schema {
    return Judoon::DB::User::Schema->connect('dbi:SQLite:judoon.sqlite');
}

__PACKAGE__->meta->make_immutable;

1;
__END__
