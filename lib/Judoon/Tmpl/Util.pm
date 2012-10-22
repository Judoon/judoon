package Judoon::Tmpl::Util;

=pod

=encoding utf8

=head1 NAME

Judoon::Tmpl::Util

=head1 SYNOPSIS

 use Judoon::Tmpl::Util;

 my @nodes = jstmpl_to_nodes('{{=varname}}');

 my $js_tmpl = nodes_to_jstmpl(@nodes);

 my $native = jstmpl_to_native('{{=foo}}');

=cut

use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(
);


use Judoon::Tmpl::Translator::Dialect::Native;
use Judoon::Tmpl::Translator::Dialect::JQueryTemplate;
use Method::Signatures;

=head2 dialects

A list of supported dialects

=cut

sub dialects { return qw(Native JQueryTemplate); }

my %dialects = map {
    my $dialect = $_;
    my $class = "Judoon::Tmpl::Translator::Dialect::$dialect";
    $_ => $class->new;
} dialects();


=head2 translate(from => C<$from>, to => C<$to>, template => C<$template>)

Translate C<$template> from the C<$from> dialect to the C<$to> dialect.
C<$template> is a string, C<$to> and C<$from> are the names of dialects,
as found in the L<dialects()> sub.

=cut

func translate(:$from!, :$to!, :$template!) {
    my @native_objects = to_objects(from => $from, template => $template);
    return $dialects{$to}->produce(\@native_objects);
}


=head2 to_objects(from => C<$from>, template => C<$template>)

C<to_objects()> turns template strings in the C<$from> dialect into an
arrayref of L<Judoon::Tmpl::Node> objects.

=cut

func to_objects(:$from!, :$template!) {
    die "$from is not a valid dialect" if (not grep {$_ eq $from} dialects());
    return $dialects{$from}->parse($template);
}


=head2 from_objects(to => C<$to>, objects => C<$objects>)

C<from_objects()> turns an arrayref of L<Judoon::Tmpl::Node> objects into a
template string in the C<$to> dialect.

=cut

func from_objects(:$to!, :$objects!) {
    die "$to is not a valid dialect" if (not grep {$_ eq $to} dialects());
    return $dialects{$to}->produce($objects);
}


func jstmpl_to_nodes($template) {
    return to_objects(from => 'JQueryTemplate', template => $template);
}

func nodes_to_jstmpl($template) {
    return from_objects(to => 'JQueryTemplate', template => $template);
}

func native_to_nodes($template) {
    return to_objects(from => 'Native', template => $template);
}

func nodes_to_native($template) {
    return from_objects(to => 'Native', template => $template);
}


1;
__END__
