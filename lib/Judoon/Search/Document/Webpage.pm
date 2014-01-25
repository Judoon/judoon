package Judoon::Search::Document::Webpage;
use Elastic::Doc;
use MooseX::Types::Moose qw(Str);
with 'Judoon::Search::Document::Role::Webmeta';


no Elastic::Doc;
1;
__END__

=pod

=encoding utf8

=head1 NAME

Judoon::Search::Document::Webpage - Document representing a Webpage

=head1 DESCRIPTION

This Document represents an instance of a static webpage on the Judoon
site.

=head1 AUTHOR

Fitz ELLIOTT <felliott@fiskur.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by the Rector and Visitors of the
University of Virginia.

This is free software, licensed under:

 The Artistic License 2.0 (GPL Compatible)

=cut
