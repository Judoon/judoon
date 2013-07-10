package Judoon::Search::Document::Page;
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

Judoon::Search::Document::Page - Document representing a Page

=head1 DESCRIPTION

This Document represents an instance of a
L<Judoon::Schema::Result::Page>.

=cut
