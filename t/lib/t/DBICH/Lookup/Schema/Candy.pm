package t::DBICH::Lookup::Schema::Candy;

use parent 'DBIx::Class::Candy';

sub base { 't::DBICH::Lookup::Schema::BaseResult' }

1;
