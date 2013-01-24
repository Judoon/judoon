package t::DBIC::Components::Schema::Genre;

use t::DBIC::Components::Schema::Candy;

table 'genres';

primary_column 'id' => serial_integer;
text_column 'genre';

unique_constraint unique_genre_name => ['genre'];

1;
