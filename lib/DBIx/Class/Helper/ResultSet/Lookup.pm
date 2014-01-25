package DBIx::Class::Helper::ResultSet::Lookup;

use strict;
use warnings;

use Scalar::Util qw(blessed);


sub new_result {
    my ($self, $values) = @_;
    $self->_replace_lookup_values($values);
    return $self->next::method($values);
}


sub update {
    my ($self, $values) = @_;
    $self->_replace_lookup_values($values);
    return $self->next::method($values);
}


sub _replace_lookup_values {
    my ($self, $values) = @_;

    for my $lookup_info (values %{ $self->result_class->__lookup_map }) {
        my $acc = $lookup_info->{accessor};
        next unless (exists $values->{$acc});

        my $lookup_val = delete $values->{$acc};
        my $lookup_rel = $lookup_info->{rel};
        my $lookup_obj = $self->result_class->_get_lookup_obj(
            $self->result_source, $lookup_rel,
            $lookup_info->{column}, $lookup_val,
        );

        $self->_update_values_from_related($lookup_rel, $lookup_obj, $values);
    }

    return;
}


# This is a copy of DBIx::Class::Relationship::Base::set_from_related(),
# except that it sets the key fields in the $values parameter, rather
# than directly into the object.
sub _update_values_from_related {
  my ($self, $rel, $f_obj, $values) = @_;

  my $rsrc = $self->result_source;
  my $rel_info = $rsrc->relationship_info($rel)
    or $self->throw_exception( "No such relationship ${rel}" );

  if (defined $f_obj) {
    my $f_class = $rel_info->{class};
    $self->throw_exception( "Object $f_obj isn't a ".$f_class )
      unless blessed $f_obj and $f_obj->isa($f_class);
  }


  # FIXME - this is a bad position for this (also an identical copy in
  # new_related), but I have no saner way to hook, and I absolutely
  # want this to throw at least for coderefs, instead of the "insert a NULL
  # when it gets hard" insanity --ribasushi
  #
  # sanity check - currently throw when a complex coderef rel is encountered
  # FIXME - should THROW MOAR!
  my ($cond, $crosstable, $relcols) = $rsrc->_resolve_condition (
    $rel_info->{cond}, $f_obj, $rel, $rel
  );
  $self->throw_exception("Custom relationship '$rel' does not resolve to a join-free condition fragment")
    if $crosstable;
  $self->throw_exception(sprintf (
    "Custom relationship '%s' not definitive - returns conditions instead of values for column(s): %s",
    $rel,
    map { "'$_'" } @$relcols
  )) if @{$relcols || []};

  for my $k (keys %$cond) {
    $values->{$k} = $cond->{$k};
  }

  return 1;
}


1;
__END__

=pod

=head1 NAME

DBIx::Class::Helper::ResultSet::Lookup - easily set your lookup relations by value

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

In resultset class:

 package My::Schema::ResultSet::CD;

 __PACKAGE__->load_components(qw/Helper::ResultSet::Lookup/);

In your script:

 my $cd_rs = $schema->resultset('CD');


 # these work, assuming 'metal' & 'stoner metal' are valid genres.
 my $cd = $cd_rs->new_result({
     artist => 'High on Fire', title => 'Blessed Black Wings',
     genre => 'metal',
 });

 $cd->update({ genre => 'stoner metal' });

 $cd_rs->search_rs({artist => 'High on Fire'})
     ->update({ genre => 'stoner metal' });

 $cd_rs->search_rs({artist => 'High on Fire'})
     ->update_all({ genre => 'stoner metal' });


 # these die with "not a valid lookup" error message
 my $cd = $cd_rs->new_result({
     artist => 'High on Fire', title => 'Blessed Black Wings',
     genre => 'cheddar cheese',
 });

 $cd_rs->search_rs({artist => 'High on Fire'})
     ->update({ genre => 'avocadocore' });

 $cd_rs->search_rs({artist => 'High on Fire'})
     ->update_all({ genre => 'thumb-step' });

 $cd_rs->first->update({ genre => 'tuvan elbow-singing' });


=head1 DESCRIPTION

This module simplifies creating and updating resultsets and row
objects with lookup fields.  The hashrefs passed to
C<$rs->new_result()>, C<$rs->update()>, or C<$row->update()> are
scanned for keys with the same name as the C<lookup_proxy> defined in
the result source.  If any are found, the values are looked up in the
related table and the key id is added to the hashref.  e.g. assuming a
Customer result class that has defined a C<lookup_proxy> to the
Country result class.

 $customer_rs->new_result({name => 'Sven', country => 'Sweden'});
 # ...becomes:
 $customer_rs->new_result({
     name       => 'Sven',
     country_id => $country_rs->find({name => 'Sweden'})->id,
 });


 my $sven_rs = $customer_rs->search_rs({name => {like => 'Sven%'}});
 $sven_rs->update({country => 'Sweden'});
 # ...becomes:
 $sven_rs->update({
     country_id => $country_rs->find({name => 'Sweden'})->id,
 });

If the given value is not found in the lookup table, the method dies
with an invalid lookup error, thus preventing insertion of bogus data.

See L<DBIx::Class::Helper::Row::Lookup> for more information.  This
module does nothing if the result class has not loaded the
C<Helper::Row::Lookup> component.

=for Pod::Coverage new_result / update


=head1 AUTHOR

Fitz ELLIOTT <felliott@fiskur.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by the Rector and Visitors of the
University of Virginia.

This is free software, licensed under:

 The Artistic License 2.0 (GPL Compatible)

=cut
