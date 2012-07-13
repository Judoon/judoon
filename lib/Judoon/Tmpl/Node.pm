package Judoon::Tmpl::Node;

use Moose;
use MooseX::Storage;
use namespace::autoclean;

our $VERSION = '0.001';

with Storage(format => 'JSON');

around 'pack' => sub {
    my $orig  = shift;
    my $self = shift;

    my $return = $self->$orig();
    $return->{type} = $self->type;
    return $return;
};


=head2 type

This method simply returns a string that describes the node type.
This is a virtual method that must be implemented by subclasses.

=cut

sub type { ... }


=head2 decompose

This method takes a node and returns a simpler representation of it
comprised only of Text and Variable nodes.  This is a virtual method
that must be implemented by subclasses.

=cut

sub decompose { ... }

__PACKAGE__->meta->make_immutable;

1;
__END__
