package Judoon::Tmpl::Factory;

=pod

=encoding utf8

=cut

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


=head2 build_node

Create a L<Judoon::Tmpl::Node> based upon the contents of the
representative hashref.

=cut

sub build_node {
    my ($args) = @_;
    return $args->{type} eq 'text'     ? new_text_node($args)
        :  $args->{type} eq 'variable' ? new_variable_node($args)
        :  $args->{type} eq 'link'     ? new_link_node($args)
        :  $args->{type} eq 'newline'  ? new_newline_node($args)
        :      die "unrecognized node type: " . $args->{type};
}


=head2 new_text_node / new_variable_node / new_link_node / new_newline_node

Explicitly create new Judoon::Tmpl::Nodes

=cut

sub new_text_node     { Judoon::Tmpl::Node::Text->new(    $_[0]); }
sub new_variable_node { Judoon::Tmpl::Node::Variable->new($_[0]); }
sub new_link_node     { Judoon::Tmpl::Node::Link->new(    $_[0]); }
sub new_newline_node  { Judoon::Tmpl::Node::Newline->new(      ); }



1;
__END__
