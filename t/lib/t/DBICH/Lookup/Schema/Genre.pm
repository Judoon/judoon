package t::DBICH::Lookup::Schema::Genre;

use t::DBICH::Lookup::Schema::Candy;

table 'genres';

primary_column 'id' => serial_integer;
text_column 'genre';

unique_constraint unique_genre_name => ['genre'];

1;
