package Judoon::DB::User::Schema::ResultSet::Dataset;

=pod

=encoding utf8

=cut

use strict;
use warnings;
use feature ':5.10';
use base 'DBIx::Class::ResultSet';
sub public {
    my ($self) = @_;
    return $self->search({permission => 'public'}, {join => 'permission'});
}

# #use feature ':5.10';
# use Moose;
# use namespace::autoclean;
# use MooseX::NonMoose;
# extends 'DBIx::Class::ResultSet';
# use Data::Printer;
# sub FOREIGNBUILDARGS { $DB::single=1; $_[2] }
# #with 'Judoon::DB::User::Schema::Role::ResultSet::HasPermissions';
# __PACKAGE__->meta->make_immutable;

1;
__END__
