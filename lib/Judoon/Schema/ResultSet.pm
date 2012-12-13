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
extends 'DBIx::Class::ResultSet';

__PACKAGE__->load_components(qw(
    Helper::ResultSet::IgnoreWantarray
    Helper::ResultSet::Me
));


=head1 METHODS

=head2 _glob_to_like( $kinda_like )

Turn a globby string into a L<SQL::Abstract> LIKE-compatible data
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
