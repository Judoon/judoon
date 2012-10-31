package Judoon::Tmpl::Translator::Dialect::Data;

=pod

=encoding utf8

=head1 NAME

Judoon::Tmpl::Translator::Dialect::Data

=head1 SYNOPSIS

 my $arrayref = Judoon::Tmpl::Util::translate(
     from => 'JQueryTemplate', to => 'Data',
     template => $jq_tmpl,
 );

=head1 DESCRIPTION

This module can parse and produce JSON strings to and from a list of
C<Judoon::Tmpl> nodes.

=cut

use Moo;

with 'Judoon::Tmpl::Translator::Dialect';

use Judoon::Tmpl::Util ();

=head1 METHODS

=head2 B<C<parse>>

The C<Data> C<parse()> method takes an arrayref of hashrefs and
attempts to turn them into a list of C<Judoon::Tmpl::Node::*>
nodes.

=cut

sub parse {
    my ($self, $input) = @_;
    die 'input to parse() is not an arrayref!' unless (ref($input) eq 'ARRAY');
    return map {Judoon::Tmpl::Util::build_node($_)} @$input;
}


=head2 B<C<produce>>

The C<produce> method takes an arrayref of C<Judoon::Tmpl::Nodes> and
outputs an arrayref of hashrefs  representing them.

=cut

sub produce {
    my ($self, $native_objects) = @_;
    my @output = map {$_->pack} @$native_objects;
    return \@output;
}


1;
__END__
