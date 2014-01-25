package Judoon::Search;

use Elastic::Model;

has_namespace 'judoon' => {
    webpage => 'Judoon::Search::Document::Webpage',
    user    => 'Judoon::Search::Document::User',
    dataset => 'Judoon::Search::Document::Dataset',
    page    => 'Judoon::Search::Document::Page',
};


__PACKAGE__->meta->make_immutable;
1;
__END__

=pod

=encoding utf8

=head1 NAME

Judoon::Search - interface to our ElasticSearch search engine

=head1 DESCRIPTION

See L</Elastic::Model>.  Default namespace is 'C<judoon>'.

=head1 AUTHOR

Fitz ELLIOTT <felliott@fiskur.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by the Rector and Visitors of the
University of Virginia.

This is free software, licensed under:

 The Artistic License 2.0 (GPL Compatible)

=cut
