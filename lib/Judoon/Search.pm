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

See L</Elastic::Model>.  Default namespace is 'judoon'.

=cut
