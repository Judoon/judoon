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
has description => (
    traits   => ['ElasticField'],
    is       => 'ro',
    isa      => Str,
    required => 1,
    index    => 'analyzed',
);
has content => (
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
has retrieved => (
    traits   => ['ElasticField'],
    is       => 'ro',
    isa      => DateTime,
    required => 1,
    default  => sub { DateTime->now; },
);

no Elastic::Doc;
1;
__END__

=pod

=encoding utf8

=head1 NAME

Judoon::Search::Document::Role::Webmeta - Webpage-related metadata

=head1 DESCRIPTION

A Document that consumes this role is available as a webpage with the
following properties:

=head1 ATTRIBUTES

=head2 title

The title of the webpage

=head2 description

A short description of the content of the page. This field
will be analyzed for full-text search purposes.

=head2 content

The full contents of the page. This field will be analyzed for
full-text search purposes.

=head2 url

The url this page can be accessed at.

=head2 retrieved

The date this page was retrieved.

=head1 AUTHOR

Fitz ELLIOTT <felliott@fiskur.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by the Rector and Visitors of the
University of Virginia.

This is free software, licensed under:

 The Artistic License 2.0 (GPL Compatible)

=cut
