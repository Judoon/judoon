package t::DBIC::Components::Schema::SportType;

use t::DBIC::Components::Schema::Candy;

table 'sport_types';

primary_column 'id' => serial_integer;
text_column 'type';

unique_constraint unique_sport_type => ['type'];

1;
__END__
