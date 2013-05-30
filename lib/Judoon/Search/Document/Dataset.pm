package Judoon::Search::Document::Dataset;
use Elastic::Doc;
with 'Judoon::Search::Document::Role::Webmeta',
     'Judoon::Search::Document::Role::TabularData',
     'Judoon::Search::Document::Role::Permission',;
no Elastic::Doc;
1;
__END__
