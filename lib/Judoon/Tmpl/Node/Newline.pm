package Judoon::Tmpl::Node::Newline;

=pod

=encoding utf8

=head1 NAME

Judoon::Tmpl::Node::Newline - A Node that represents an HTML line break

=cut

use Moose;
use namespace::autoclean;

with qw(
    Judoon::Tmpl::Node::Role::Base
    Judoon::Tmpl::Node::Role::Composite
    Judoon::Tmpl::Node::Role::Formatting
);


has '+type' => (default => 'newline',);


=head1 METHODS

=head2 decompose

A C<Newline> node decomposes to a C<Text> node whose C<value> is
C<E<lt>brE<gt>>.

=cut

sub decompose {
    my ($self) = @_;
    return $self->make_text_node("<br>");
}


__PACKAGE__->meta->make_immutable;

1;
__END__
