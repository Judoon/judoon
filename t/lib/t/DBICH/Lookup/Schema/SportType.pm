package t::DBICH::Lookup::Schema::SportType;

use t::DBICH::Lookup::Schema::Candy;

table 'sport_types';

primary_column 'id' => serial_integer;
text_column 'type';

unique_constraint unique_sport_type => ['type'];

1;
__END__
