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


=head2 decompose_plaintext()

A Newline is a text component.

=cut

sub decompose_plaintext {
    my ($self) = @_;
    return $self->make_text_node("\n");
}


__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 AUTHOR

Fitz ELLIOTT <felliott@fiskur.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by the Rector and Visitors of the
University of Virginia.

This is free software, licensed under:

 The Artistic License 2.0 (GPL Compatible)

=cut
