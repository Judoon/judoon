package Judoon::Tmpl::Translator::Dialect::JQueryTemplate;

use Moo;
use feature ':5.10';

with 'Judoon::Tmpl::Translator::Dialect';

use Judoon::Tmpl::Factory qw(build_node);
use Method::Signatures;

has parser => (is => 'lazy',); # isa => 'Regexp',
sub _build_parser {
    my ($self) = @_;

    my $parser = do {
        use Regexp::Grammars;
        return qr{
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


method parse($input) {
    die "Unable to parse as JQueryTemplate: $input"
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
                    url => {type => 'varstring', varstring_type => 'static', %{$segs->{url}}},
                    label => {type => 'varstring',  varstring_type => 'static', %{$segs->{label}}},
                };
            }
        }

        push @objects, build_node($jnode);
    }

    return @objects;
};

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


1;
__END__
