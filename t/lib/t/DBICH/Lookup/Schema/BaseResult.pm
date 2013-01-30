package t::DBICH::Lookup::Schema::BaseResult;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components(qw/
    +t::DBICH::Lookup::Schema::Util
    Helper::Row::Lookup
    Helper::Row::RelationshipDWIM
/);

sub default_result_namespace { 't::DBICH::Lookup::Schema' }


1;
__END__
