package Judoon::Tmpl::Translator::Dialect::Native;

=pod

=encoding utf8

=head1 NAME

Judoon::Tmpl::Translator::Dialect::Native

=head1 SYNOPSIS

 my $json = Judoon::Tmpl::Util::translate(
     from => 'JQueryTemplate', to => 'Native',
     template => $jq_tmpl,
 );

=head1 DESCRIPTION

This module can parse and produce JSON strings to and from a list of
C<Judoon::Tmpl> nodes.

=cut

use Moo;

with 'Judoon::Tmpl::Translator::Dialect';

use Judoon::Tmpl::Util ();
use JSON qw(to_json from_json);

my $json_opts = {utf8 => 1};

=head1 METHODS

=head2 B<C<parse>>

The C<Native> C<parse()> method takes a JSON string and attempts to
parse it into a list of C<Judoon::Tmpl::Node::*> nodes.

=cut

sub parse {
    my ($self, $input) = @_;
    my $native_struct = from_json($input, $json_opts);
    return map {Judoon::Tmpl::Util::build_node($_)} @$native_struct;
}


=head2 B<C<produce>>

The C<produce> method takes an arrayref of C<Judoon::Tmpl::Node>s and
outputs a JSON string representing them.

=cut

sub produce {
    my ($self, $native_objects) = @_;
    my @output = map {$_->pack} @$native_objects;
    return to_json(\@output, $json_opts);
}


1;
__END__
