package Judoon::Schema::Candy;

use Moo;
extends 'DBIx::Class::Candy';

sub base { 'Judoon::Schema::Result' }


1;
__END__
