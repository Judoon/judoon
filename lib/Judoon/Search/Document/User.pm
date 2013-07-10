package Judoon::Search::Document::User;
use Elastic::Doc;

use MooseX::Types::Moose qw(Str);

for my $attr (qw(username name email_address)) {
    has $attr => (
        is       => 'ro',
        isa      => Str,
        required => 1,
        index    => 'analyzed'
    );
}

no Elastic::Doc;
1;
__END__

=pod

=encoding utf8

=head1 NAME

Judoon::Search::Document::User - Document representing a User

=head1 DESCRIPTION

This Document represents an instance of a
L<Judoon::Schema::Result::User>.

=cut
