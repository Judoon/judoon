package Judoon::Tmpl::Factory;

our $VERSION = '0.001';
use Moose;
use namespace::autoclean;

use Judoon::Tmpl::Node::Text;
use Judoon::Tmpl::Node::Variable;
use Judoon::Tmpl::Node::Link;
use Judoon::Tmpl::Node::Newline;


sub build {
    my ($self, $args) = @_;

    if ($args->{type} eq 'text') {
        return Judoon::Tmpl::Node::Text->new($args);
    }
    elsif ($args->{type} eq 'variable') {
        return Judoon::Tmpl::Node::Variable->new($args);
    }
    elsif ($args->{type} eq 'link') {
        return Judoon::Tmpl::Node::Link->new($args);
    }
    elsif ($args->{type} eq 'newline') {
        return Judoon::Tmpl::Node::Newline->new($args);
    }
}


__PACKAGE__->meta->make_immutable;

1;
__END__
