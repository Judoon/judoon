package t::DBIC::Components::Schema::CD;

use t::DBIC::Components::Schema::Candy;

table 'cds';

primary_column 'id' => serial_integer;
text_column 'artist';
text_column 'title';
foreign_key_column 'genre_id';

belongs_to(
    genre_rel => 't::DBIC::Components::Schema::Genre',
    {id => 'genre_id',},
    { join_type => 'left',  lookup_proxy => 'genre', }
);

1;
