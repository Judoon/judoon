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

=cut
