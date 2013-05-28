package Judoon::Search::Document::Webpage;
use Elastic::Doc;
use MooseX::Types::Moose qw(Str);
with 'Judoon::Search::Document::Role::Webmeta';


no Elastic::Doc;
1;
__END__
