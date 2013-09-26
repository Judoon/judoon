package Judoon::Lookup::ExternalActor;

use Moo;
use namespace::clean;

1;
__END__

=pod

=for stopwords

=encoding utf8

=head1 NAME

Judoon::Lookup::ExternalActor - Base class of external database lookups

=head1 DESCRIPTION

This is our base class for external database lookup actors.  Lookup
actors are the objects in charge of actually taking a list of data and
translating that into new data via lookups in another data
source. Objects of this class are expected to fetch their data from a
non-Judoon data source.

These objects are constructed by the C<build_actor()> method of a
L<Judoon::Lookup::External> object.  They will have the
L<Judoon::Lookup::Role::Actor> role composed into them, along with an
action role that supplies the C<lookup()> and C<result_data_type()>
methods required by C<::Role::Actor>.

=cut
