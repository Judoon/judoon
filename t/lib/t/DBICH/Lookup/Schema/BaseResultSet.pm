package t::DBICH::Lookup::Schema::BaseResultSet;

use strict;
use warnings;

use base 'DBIx::Class::ResultSet';

__PACKAGE__->load_components('Helper::ResultSet::Lookup');


1;
__END__
