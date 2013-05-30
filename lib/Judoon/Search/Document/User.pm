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
