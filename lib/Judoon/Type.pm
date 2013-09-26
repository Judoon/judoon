package Judoon::Type;

use Moo;
extends 'Type::Tiny';
use namespace::clean;

has library => (is => 'ro');
has sample  => (is => 'ro');
has pg_type => (is => 'lazy');
sub _build_pg_type {
    my ($self) = @_;
    return $self->parent->pg_type;
}

sub TO_JSON {
    my ($self) = @_;

    return {
        name    => $self->name,
        label   => $self->display_name,
        sample  => $self->sample,
        library => $self->library,
    };
}


1;
__END__

=pod

=encoding utf8

=head1 NAME

Judoon::Type - Extension class for Type::Tiny

=head1 SYNOPSIS

 use Judoon::Type;
 use Types::Standard qw(Str);

 my $NUMISH = Judoon::Type->new(
     name         => 'Numish',
     display_name => 'A Number, but also something else?',
     parent       => Str,
     sample       => '1 and a bit',
     library      => 'Approximates',
 );

=head1 DESCRIPTION

This lets us add extra information to our Type::Tiny-based types.

=head1 ATTRIBUTES

=head2 library

The library this type is a member of.  Used for grouping.

=head2 sample

An example of this particular Type.

=head2 pg_type

The PostgreSQL type that this type derives from.

=head1 METHODS

=head2 TO_JSON

A data structure representing this type that is suitable for
serialization.

=cut
