package Judoon::Tmpl::Translator::Dialect::JQueryTemplate;

=pod

=encoding utf8

=head1 NAME

Judoon::Tmpl::Translator::Dialect::JQueryTemplate

=head1 SYNOPSIS

 my $trans = Judoon::Tmpl::Translator->new;
 my $jq_tmpl = $trans->translate(
     from => 'Native', to => 'JQueryTemplate',
     template => $native_tmpl,
 );

=head1 DESCRIPTION

This module can parse and produce jsrender-compatible HTML strings to
and from a list of C<Judoon::Tmpl> nodes.

=cut


use Moo;
use feature ':5.10';

with 'Judoon::Tmpl::Translator::Dialect';

use Judoon::Tmpl::Util ();
use Method::Signatures;

=head1 ATTRIBUTES

=head2 B<C<parser>>, B<C<_build_parser>>

A L<Regexp::Grammars>-based parser regex.

=cut

has parser => (is => 'lazy',); # isa => 'Regexp',
sub _build_parser {
    my ($self) = @_;

    my $parser = do {
        use Regexp::Grammars;
        qr{
            <nocontext:>
            (?: <[Nodes=Node]> )+

            <token: Node>
              <Link> | <Variable> | <Newline> | <Text>

            <token: Newline>
               \<br\>
            <token: Variable>
              {{=<name=(\w+)>}}
            <token: Link>
               \<a[ ]href="
               <url=UrlVarString>
               "\>
               <label=LabelVarString>
               \<\/a\>

            <token: UrlVarString>
              <[Pairs=UrlVsPair]>+
            <token: LabelVarString>
              <[Pairs=LabelVsPair]>+
            <token: VarString>
              <[Pairs=VsPair]>+

            <token: VsPair>
              <Text><Variable> | <emptytext=1><Variable> | <Text><emptyvariable=1>
            <token: UrlVsPair>
               <Text=UrlText><Variable> | <emptytext=1><Variable> | <Text=UrlText><emptyvariable=1>
            <token: LabelVsPair>
               <Text=LabelText><Variable> | <emptytext=1><Variable> | <Text=LabelText><emptyvariable=1>

            <token: Text>
              <value=(.+?)> <?TextEnd>
            <token: TextEnd>
              <Link> | <Variable> | <Newline> | $

            <token: UrlText>
              <value=([^"]+?)> <?UrlTextEnd>
            <token: UrlTextEnd>
              <Variable> | \"

            <token: LabelText>
              <value=([^"]+?)> <?LabelTextEnd>
            <token: LabelTextEnd>
              <Variable> | <Newline> | \<\/a\>
        }x;
    };
    return $parser;
}


=head1 METHODS

=head2 B<C<parse>>

The C<JQueryTemplate> C<parse()> method takes a string and attempts to
parse it into a list of C<Judoon::Tmpl::Node::*> nodes.  It dies on
C<undef> input, and returns an empty list for an empty string.  JQT
can't know the C<varstring_type> of a link component (url or label)
explicitly, so it calls the C<_varstring_type> method to guess.

=cut

method parse($input) {
    die "Cannot parse undef input as JQueryTemplate"
        if (not defined $input);
    return () if ($input eq '');
    die "Cannot parse $input as JQueryTemplate, which shouldn't be possible"
        if ($input !~ $self->parser);

    my @objects;
    for my $node (@{$/{Nodes}}) {
        my ($type) = keys %$node;
        my $rec    = $node->{$type};

        my $jnode;
        for ($type) {
            when ('Text')     { $jnode = {type => 'text', value => $rec->{value}}; }
            when ('Variable') { $jnode = {type => 'variable', name => $rec->{name}}; }
            when ('Newline')  { $jnode = {type => 'newline'}; }
            when ('Link')     {
                my $segs;
                for my $seg (qw(label url)) {
                    for my $pair (@{$rec->{$seg}{Pairs}}) {
                        push @{$segs->{$seg}{text_segments}},
                            ($pair->{Text} && $pair->{Text}{value}) // '';
                        push @{$segs->{$seg}{variable_segments}},
                            ($pair->{Variable} && $pair->{Variable}{name}) // '';
                    }
                }
                $jnode = {
                    type => 'link',
                    url  => {
                        type           => 'varstring',
                        varstring_type => $self->_varstring_type($segs->{url}),
                        %{$segs->{url}},
                    },
                    label => {
                        type           => 'varstring',
                        varstring_type => $self->_varstring_type($segs->{label}),
                        %{$segs->{label}},
                    },
                };
            }
        }

        push @objects, Judoon::Tmpl::Util::build_node($jnode);
    }

    return @objects;
};


=head2 B<C<produce>>

The C<produce> method takes a list of C<Judoon::Tmpl> nodes and
outputs a jsrender-compatible HTML string.

=cut

method produce(\@native_objects) {

    my @objects = @native_objects;
    my $template = q{};
    while (my $node = shift @objects) {

        if ($node->does('Judoon::Tmpl::Node::Role::Composite')) {
            unshift @objects, $node->decompose();
            next;
        }

        my @text = $node->type eq 'text'     ? $node->value
                 : $node->type eq 'variable' ? '{{=' . $node->name . '}}'
                 :     die "Unrecognized node type! " . $node->type;

        if (my @formats = @{$node->formatting}) {
            if (grep {m/bold/} @formats) {
                @text = ('<strong>',@text,'</strong>');
            }
            if (grep {m/italic/} @formats) {
                @text = ('<em>',@text,'</em>');
            }
        }

        $template .= join '', @text;
    }

    return $template;
}


=head2 B<C<_varstring_type>>

The C<_varstring_type> method takes a varstring struct and attempts to
guess its type based upon the presence of non-empty C<variable_segments>.

=cut

method _varstring_type($varstring) {
    return (exists($varstring->{variable_segments})
        && grep {m/\S/} @{$varstring->{variable_segments}})
            ? 'variable' : 'static';
}

1;
__END__
