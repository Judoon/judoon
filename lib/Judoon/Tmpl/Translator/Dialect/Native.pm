package Judoon::Tmpl::Translator::Dialect::Native;

=pod

=encoding utf8

=head1 NAME

Judoon::Tmpl::Translator::Dialect::Native

=head1 SYNOPSIS

 my $trans = Judoon::Tmpl::Translator->new;
 my $json = $trans->translate(
     from => 'JQueryTemplate', to => 'Native',
     template => $jq_tmpl,
 );

=head1 DESCRIPTION

This module can parse and produce JSON strings to and from a list of
C<Judoon::Tmpl> nodes.

=cut

use Moo;

with 'Judoon::Tmpl::Translator::Dialect';

use Judoon::Tmpl::Factory;
use JSON qw(encode_json decode_json);
use Method::Signatures;


=head1 METHODS

=head2 B<C<parse>>

The C<Native> C<parse()> method takes a JSON string and attempts to
parse it into a list of C<Judoon::Tmpl::Node::*> nodes.

=cut

method parse($input) {
    my $native_struct = decode_json($input);
    return map {build_node($_)} @$native_struct;
}


=head2 B<C<produce>>

The C<produce> method takes a list of C<Judoon::Tmpl> nodes and
outputs a JSON string representing them.

=cut

method produce(\@native_objects) {
    my @output = map {$_->pack} @native_objects;
    return encode_json(\@output);
}


1;
__END__
