package DBIx::Class::Helper::Row::Lookup;

use strict;
use warnings;
use Sub::Name ();
use base 'DBIx::Class';

__PACKAGE__->mk_classdata( __lookup_map => {} );


sub update {
    my ($self, $upd) = @_;
    my $rs = $self->result_source->resultset;
    if ($rs->can('_replace_lookup_values')) {
        $rs->_replace_lookup_values($upd);
    }
    return $self->next::method($upd);
}


# register_relationship and _build_proxy_map_from are mostly
# cut-n-pasted from DBIx::Class::Relationship::ProxyMethods with minor
# changes. proxy_to_lookup() is proxy_to_related() with find-or-die
# semantics.
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

        $class->__lookup_map->{$meth_name}{rel}      = $rel;
        $class->__lookup_map->{$meth_name}{accessor} = $meth_name;
        $class->__lookup_map->{$meth_name}{column}   = $proxy_to_col;

        my $name = join '::', $class, $meth_name;
        *$name = Sub::Name::subname $name => sub {
            my $self = shift;
            my $relobj = $self->$rel;

            if (@_) {
                my $newobj = $self->_get_lookup_obj(
                    $self->result_source, $rel, $proxy_to_col, $_[0]
                );
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


# stupidly compare two lookup objects, so we can avoid setting if
# they're already the same
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


# must be passed result_source ($rsrc) b/c this can be called on a row
# or resultset
sub _get_lookup_obj {
    my ($class, $rsrc, $lookup_rel, $lookup_col, $lookup_val) = @_;
    my $rel_class  = $rsrc->related_class($lookup_rel);
    my $lookup_obj = $rsrc->schema->resultset($rel_class)
        ->find({ $lookup_col => $lookup_val })
            or $class->throw_exception(qq{Value "$lookup_val" not found in lookup relationship $lookup_rel});
    return $lookup_obj;
}


1;
__END__

=pod

=head1 NAME

DBIx::Class::Helper::Row::Lookup - proxy related fields with find-or-die behavior

=head1 SYNOPSIS

In result class:

 package My::Schema::Result::CD;

 __PACKAGE__->load_components(qw/Helper::Row::Lookup Core/);

 __PACKAGE__->add_columns(
   genre_id => {
       data_type      => 'integer',
       is_foreign_key => 1,
       is_nullable    => 0,
   },
 );

 __PACAKGE__->belongs_to(
   genre_rel => 'My::Schema::Result::Genre',
   {'foreign.id' => 'self.genre_id',},
   {lookup_proxy => 'genre',},
 );

 1;

In your script:

 my $cd_rs = $schema->resultset('CD');
 my $genre_rs = $schema->resultset('Genre');

 my $cd = $cd_rs->find({artist => 'High on Fire', name => 'Snakes for the Divine'});
 $cd->genre();  # 'metal'
 $cd->genre('stoner rock'); # ok. cd.genre_id = $genre_rs->find({'stoner rock'})->id
 $cd->genre('avocadocore'); # dies! "avocadocore" is not a valid lookup in "genre_rel"

=head1 DESCRIPTION

This module adds support for a new relationship attribute,
C<lookup_proxy>.  C<lookup_proxy> is similar to the C<proxy>
attribute, but where the C<proxy> accessor uses find-or-create
semantics when used as a setter, C<lookup_proxy> uses find-or-die
instead.  This is handy for lookup tables (a.k.a. type tables) where
the possible related values should be limited to what's already in the
related table.  For example, if your Customer result has a foreign key
into a Country table, it's nice to be able to write:

 $customer_obj->country("Sweden");

instead of:

 $customer_obj->country_rel( $country_rs->find({name => "Sweden"}) );

However, you don't want:

  $customer_obj->country("Swedenf");

to suddenly invent a brand-new country in your database.  With
C<lookup_proxy>, this code will die screaming and you and your lineage
will benefit from a thousand years of Swedish goodwill.

=head2 Going further

If you load C<DBIx::Class::Helper::ResultSet::Lookup> into the
resultset class of a result using C<lookup_proxy>, you'll get an extra
bit of sugar: you can pass your types to C<new_result()> and
C<update()> and have them automatically translated into related
objects with the same find-or-die protection.  e.g:

 $customer_rs->new_result({name => 'Sven', country => 'Sweden'});
 # is automatically translated to:
 $customer_rs->new_result({
     name       => 'Sven',
     country_id => $country_rs->find({name => 'Sweden'})->id,
 });

 $customer_rs->search_rs({name => {like => 'Sven%'}})
     ->update({country => 'Sweden'});

=head2 Naming convention

Feel free to completely disregard this bit, but when working with
lookup tables, I like to use the following convention. Assuming the
Customer/Country schema:

 ::Result::Customer
 table 'customers';
 column 'country_id';

 belongs_to(
     'country_rel' => '::Result::Country',
     {id => 'country_id'},
     {lookup_proxy => {country => 'name'},},
 );

 ::Result::Country
 table 'countries';
 column 'name' => { data_type => 'text',};

That is, the relationship is C<${foo}_rel>, the lookup accessor is
C<$foo>, and the foreign key field is C<${foo}_id>.


=head1 METHODS

=head2 proxy_to_lookup

Installs the lookup accessors into the Row object.

=for Pod::Coverage update register_relationship


=head1 AUTHOR

Fitz ELLIOTT <felliott@fiskur.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by the Rector and Visitors of the
University of Virginia.

This is free software, licensed under:

 The Artistic License 2.0 (GPL Compatible)

=cut
