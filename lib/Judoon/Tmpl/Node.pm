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

sub type { ... }
sub decompose { ... }

__PACKAGE__->meta->make_immutable;

1;
__END__
