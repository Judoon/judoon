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
