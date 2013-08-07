package Judoon::Type;

use Moo;

extends 'Type::Tiny';

has label  => (is => 'ro');
has sample => (is => 'ro');


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
     name   => 'Numish',
     parent => Str,
     sample => '1 and a bit',
     label  => 'A Number, but also something else?',
 );

=head1 DESCRIPTION

This lets us add extra information to our Type::Tiny-based types.

=head1 ATTRIBUTES

=head2 label

A nice human-readable name for this Type.

=head2 sample

An example of this particular Type.

=cut
