package Judoon::Search::Document::Role::Webmeta;

use Moose::Role;

use MooseX::Types::DateTime qw(DateTime);
use MooseX::Types::Moose qw(Str);
use MooseX::Types::URI qw(Uri);

use DateTime;
use URI;

has title => (
    traits   => ['ElasticField'],
    is       => 'ro',
    isa      => Str,
    required => 1,
    index    => 'analyzed',
);
has body => (
    traits   => ['ElasticField'],
    is       => 'ro',
    isa      => Str,
    required => 1,
    index    => 'analyzed',
);
has description => (
    traits   => ['ElasticField'],
    is       => 'ro',
    isa      => Str,
    required => 1,
    index    => 'analyzed',
);
has url => (
    traits   => ['ElasticField'],
    is       => 'ro',
    isa      => Uri,
    required => 1,
    index    => 'not_analyzed',
    type     => 'string',
    deflator => sub { return shift->as_string; },
    inflator => sub { return URI->new(shift);  },
);
has retrieved  => (
    traits   => ['ElasticField'],
    is       => 'ro',
    isa      => DateTime,
    required => 1,
    default  => sub { DateTime->now; },
);

no Elastic::Doc;
1;
__END__
