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
