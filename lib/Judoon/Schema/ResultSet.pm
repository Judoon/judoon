package Judoon::Schema::ResultSet;

=pod

=encoding utf8

=head1 NAME

Judoon::Schema::ResultSet

=head1 DESCRIPTION

Base class for C<Judoon::Schema::ResultSet::*> classes. A convenient
place to set defaults.

=cut

use 5.10.1;

use Moo;
use namespace::clean;

extends 'DBIx::Class::ResultSet';

__PACKAGE__->load_components(qw(
    Helper::ResultSet::IgnoreWantarray
    Helper::ResultSet::Me
    Helper::ResultSet::SearchOr
    Helper::ResultSet::Shortcut
    Helper::ResultSet::SetOperations
));


=head1 METHODS

=head2 _glob_to_like( $kinda_like )

Turn a glob-like string into a L<SQL::Abstract> LIKE-compatible data
structure. Ex:

 *moo*  ==  {-like => '*moo*'}

If no substitutions are made, return the string unmodified so we can
do a simple equals comparison.

=cut

sub _glob_to_like {
    my ($self, $kinda_like) = @_;

    my $like = $kinda_like;

    my $subst = 0;
    $subst += $like =~ s/\*/%/g;
    $subst += $like =~ s/\?/_/g;

    return { -like => $like } if $subst;
    return $kinda_like
}


1;

=head1 AUTHOR

Fitz ELLIOTT <felliott@fiskur.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by the Rector and Visitors of the
University of Virginia.

This is free software, licensed under:

 The Artistic License 2.0 (GPL Compatible)

=cut
