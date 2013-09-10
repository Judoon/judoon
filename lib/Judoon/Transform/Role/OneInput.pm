package Judoon::Transform::Role::OneInput;

use Moo::Role;

use MooX::Types::MooseLike::Base qw(Str);

has input_field => (
    is       => 'ro',
    isa      => Str, #TransformInput,
    required => 1,
);


1;
__END__

=pod

=encoding utf8

=head1 NAME

Judoon::Transform::Role::OneInput - For Transforms that accept one input

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head2 input_field

=cut
