package Judoon::Tmpl::Util;

=pod

=encoding utf8

=head1 NAME

Judoon::Tmpl::Util

=head1 SYNOPSIS

 use Judoon::Tmpl::Util;

 # translator functions
 my @nodes = jstmpl_to_nodes('{{=varname}}');
 my $js_tmpl = nodes_to_jstmpl(@nodes);
 my $native = jstmpl_to_native('{{=foo}}');

=cut

use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(
    translate to_objects from_objects dialects
    jstmpl_to_nodes nodes_to_jstmpl native_to_nodes nodes_to_native
);

use Params::Validate qw(:all);

use Judoon::Tmpl::Translator::Dialect::Native;
use Judoon::Tmpl::Translator::Dialect::JQueryTemplate;


=head1 Translator Functions

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

sub translate {
    validate(@_, {from => 1, to => 1, template => 1});
    my %args = @_;
    my @native_objects = to_objects(
        from => $args{from}, template => $args{template},
    );
    return from_objects(to => $args{to}, objects => \@native_objects);
}


=head2 to_objects(from => C<$from>, template => C<$template>)

C<to_objects()> turns template strings in the C<$from> dialect into an
arrayref of L<Judoon::Tmpl::Node> objects.

=cut

sub to_objects {
    validate(@_, {from => 1, template => 1});
    my %args = @_;
    die "$args{from} is not a valid dialect" if (not grep {$_ eq $args{from}} dialects());
    return $dialects{$args{from}}->parse($args{template});
}


=head2 from_objects(to => C<$to>, objects => C<$objects>)

C<from_objects()> turns an arrayref of L<Judoon::Tmpl::Node> objects into a
template string in the C<$to> dialect.

=cut

sub from_objects {
    validate(@_, {to => 1, objects => 1});
    my %args = @_;
    my $to = $args{to}; my $objects = $args{objects};
    die "$to is not a valid dialect" if (not grep {$_ eq $to} dialects());
    return $dialects{$to}->produce($objects);
}


sub jstmpl_to_nodes {
    my ($template) = @_;
    return to_objects(from => 'JQueryTemplate', template => $template);
}

sub nodes_to_jstmpl {
    my @nodes = @_;
    return from_objects(to => 'JQueryTemplate', objects => \@nodes);
}

sub native_to_nodes {
    my ($template) = @_;
    return to_objects(from => 'Native', template => $template);
}

sub nodes_to_native {
    my @nodes = @_;
    return from_objects(to => 'Native', objects => \@nodes);
}


1;
__END__
