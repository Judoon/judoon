package Judoon::Tmpl::Node::Role::Formatting;

=pod

=for stopwords bolded

=encoding utf8

=head1 NAME

Judoon::Tmpl::Node::Role::Formatting

=head1 DESCRIPTION

L<Judoon::Tmpl::Node>s that can be formatted (i.e. bolded or
italicized) should compose this.

=cut

use Moose::Role;
use namespace::autoclean;

=head1 Attributes

=head2 formatting

An ArrayRef of strings containing the list of formatting properties.

=cut

has formatting => (is => 'ro', isa => 'ArrayRef[Str]', default => sub { []; },);

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
