package Judoon::Tmpl::Factory;

use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(
    build_node new_text_node new_variable_node new_link_node new_newline_node
);


use Judoon::Tmpl::Node::Text;
use Judoon::Tmpl::Node::Variable;
use Judoon::Tmpl::Node::Link;
use Judoon::Tmpl::Node::Newline;

sub build_node {
    my ($args) = @_;
    return $args->{type} eq 'text'     ? new_text_node($args)
        :  $args->{type} eq 'variable' ? new_variable_node($args)
        :  $args->{type} eq 'link'     ? new_link_node($args)
        :  $args->{type} eq 'newline'  ? new_newline_node($args)
        :      die "unrecognzied node type: " . $args->{type};
}

sub new_text_node     { Judoon::Tmpl::Node::Text->new(    $_[0]); }
sub new_variable_node { Judoon::Tmpl::Node::Variable->new($_[0]); }
sub new_link_node     { Judoon::Tmpl::Node::Link->new(    $_[0]); }
sub new_newline_node  { Judoon::Tmpl::Node::Newline->new(      ); }



1;
__END__
