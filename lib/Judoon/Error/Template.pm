package Judoon::Error::Template;

use MooX::Types::MooseLike::Base qw(ArrayRef HashRef Str);

use Moo;
extends 'Judoon::Error';
use namespace::clean;


has templates     => (is => 'ro', isa => ArrayRef[HashRef],);
has valid_columns => (is => 'ro', isa => ArrayRef[Str],);

1;
__END__

=pod

=encoding utf8

=head1 NAME

Judoon::Error::Template - Error in user-defined template

=head1 SYNOPSIS

  my $tmpl = $page_column->template;
  if (not $tmpl->has_variable('foo')) {
    Judoon::Error::Template->throw({
      message       => "I'm the worst",
      templates     => [{column => 'foo', }],
      valid_columns => [$tmpl->get_variables],
    });
 }

=head1 ATTRIBUTES

=head2 templates

A list of hashrefs containing information about the invalid templates.
This is terrible.

=head2 valid_columns

List of the names of valid variable in the templates.

=head1 AUTHOR

Fitz ELLIOTT <felliott@fiskur.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by the Rector and Visitors of the
University of Virginia.

This is free software, licensed under:

 The Artistic License 2.0 (GPL Compatible)

=cut
