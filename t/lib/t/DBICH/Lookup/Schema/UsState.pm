package t::DBICH::Lookup::Schema::UsState;

use t::DBICH::Lookup::Schema::Candy;

table 'us_states';

primary_column 'id' => serial_integer;
text_column 'name';
text_column 'state_abbr';  # inconsistently named on purpose

unique_constraint unique_state_name => ['name'];
unique_constraint unique_state_abbr => ['state_abbr'];


1;
__END__
