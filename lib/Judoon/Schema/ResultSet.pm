package Judoon::Schema::ResultSet;

use 5.10.1;

use Moo;
extends 'DBIx::Class::ResultSet';

__PACKAGE__->load_components(qw(
   Helper::ResultSet::IgnoreWantarray
   Helper::ResultSet::SetOperations
   Helper::ResultSet::ResultClassDWIM
   Helper::ResultSet::Me
));

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
