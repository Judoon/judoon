package # hide from PAUSE
    DBIx::Class::Relationship::LookupProxy;

use strict;
use warnings;
use List::Util ();
use Sub::Name ();
use base qw/DBIx::Class/;

our %_pod_inherit_config =
  (
   class_map => { 'DBIx::Class::Relationship::LookupProxy' => 'DBIx::Class::Relationship' }
  );


sub register_relationship {
  my ($class, $rel, $info) = @_;
  if (my $proxy_args = $info->{attrs}{lookup_proxy}) {
    $class->proxy_to_lookup($rel, $proxy_args);
  }
  $class->next::method($rel, $info);
}

sub proxy_to_lookup {
  my ($class, $rel, $proxy_args) = @_;
  my %proxy_map = $class->_build_proxy_map_from($proxy_args);
  no strict 'refs';
  no warnings 'redefine';
  foreach my $meth_name ( keys %proxy_map ) {
    my $proxy_to_col = $proxy_map{$meth_name};
    my $name = join '::', $class, $meth_name;
    *$name = Sub::Name::subname $name => sub {
      my $self = shift;
      my $relobj = $self->$rel;
      if (@_) {
        my $rsrc      = $self->result_source;
        my $rel_class = $rsrc->related_class($rel);
        my $newobj    = $rsrc->schema->resultset($rel_class)
            ->find({ $proxy_to_col => $_[0] })
                or die qq{Value "$_[0]" not found in lookup relationship $rel};
        if ($class->_lookup_objs_are_different($relobj, $newobj)) {
            $self->set_from_related($rel, $newobj);
            $relobj = $newobj;
        }
      }
      return ($relobj ? $relobj->$proxy_to_col() : undef);
   }
  }
}

sub _build_proxy_map_from {
  my ( $class, $proxy_arg ) = @_;
  my $ref = ref $proxy_arg;

  if ($ref eq 'HASH') {
    return %$proxy_arg;
  }
  elsif ($ref eq 'ARRAY') {
    return map {
      (ref $_ eq 'HASH')
        ? (%$_)
        : ($_ => $_)
    } @$proxy_arg;
  }
  elsif ($ref) {
    $class->throw_exception("Unable to process the 'lookup_proxy' argument $proxy_arg");
  }
  else {
    return ( $proxy_arg => $proxy_arg );
  }
}


sub _lookup_objs_are_different {
    my ($class, $obj1, $obj2) = @_;

    return 1 if (!defined($obj1) || !defined($obj2));

    my @ids1 = sort $obj1->id;
    my @ids2 = sort $obj2->id;
    return 1 if (@ids1 != @ids2);

    for my $i (0..$#ids1) {
        return 1 if ($ids1[$i] ne $ids2[$i]);
    }

    return 0;
}

1;
