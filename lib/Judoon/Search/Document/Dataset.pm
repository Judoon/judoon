package Judoon::Search::Document::Dataset;
use Elastic::Doc;
with 'Judoon::Search::Document::Role::Webmeta',
     'Judoon::Search::Document::Role::TabularData',
     'Judoon::Search::Document::Role::Permission',;
no Elastic::Doc;
1;
__END__

=pod

=encoding utf8

=head1 NAME

Judoon::Search::Document::Dataset - Document representing a Dataset

=head1 DESCRIPTION

This Document represents an instance of a
L<Judoon::Schema::Result::Dataset>.

=head1 AUTHOR

Fitz ELLIOTT <felliott@fiskur.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by the Rector and Visitors of the
University of Virginia.

This is free software, licensed under:

 The Artistic License 2.0 (GPL Compatible)

=cut
