package t::DBIC::Components::Schema::Candy;

use parent 'DBIx::Class::Candy';

sub base { 't::DBIC::Components::Schema::BaseResult' }

1;
