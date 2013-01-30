package t::DBICH::Lookup::Schema;

use strict;
use warnings;

use base 'DBIx::Class::Schema';

__PACKAGE__->load_classes(qw/UsSportsTeam SportType UsState CD Genre/);

1;
