package t::DBIC::Components::Schema::BaseResult;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components(qw/
    +t::DBIC::Components::Schema::Util
    Helper::Row::Lookup
    Helper::Row::RelationshipDWIM
/);

sub default_result_namespace { 't::DBIC::Components::Schema' }


1;
__END__
