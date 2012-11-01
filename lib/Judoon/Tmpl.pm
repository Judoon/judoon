package Judoon::Tmpl;

=pod

=encoding utf-8

=head1 NAME

Judoon::Tmpl - Object representing a template

=head1 SYNOPSIS

 use Judoon::Tmpl;

 my $template   = Judoon::Tmpl->new_from_jstmpl('foo{{=bar}}baz');
 my @variables  = $template->get_variables(); # 'bar'
 my $serialized = $template->to_native;
 my $javascript = $template->to_jstmpl;

=head1 DESCRIPTION

C<Judoon::Tmpl> is an object that represents a template.

=cut

use Moo;
use MooX::Types::MooseLike::Base qw(ArrayRef ConsumerOf RegexpRef);
use feature ':5.10';


use JSON qw(to_json from_json);
use Judoon::Tmpl::Node::Text;
use Judoon::Tmpl::Node::Variable;
use Judoon::Tmpl::Node::Link;
use Judoon::Tmpl::Node::Newline;
use Judoon::Tmpl::Node::VarString;

my $json_opts = {utf8 => 1,};


=head1 ATTRIBUTES

=head2 nodes / _build_nodes

C<nodes> is the list of C<Judoon::Tmpl::Node::*> objects that make up
the template.  It unlikely that you will create a new C<Judoon::Tmpl>
object giving it a list of nodes; instead you probably want to use one
of the L</"Alternative Constructors">.

=cut

has nodes => (
    is  => 'lazy',
    isa => ArrayRef[ConsumerOf('Judoon::Tmpl::Node::Base')],
);
sub _build_nodes { return []; }


=head1 Node methods

These are convenience methods for getting / querying the node list.

=head2 get_nodes

Returns the list of nodes

=cut

sub get_nodes  { return @{ shift->nodes }; }


=head2 node_count

Returns the number of nodes

=cut

sub node_count { return scalar shift->get_nodes; }


=head2 node_types

Returns a list of the C<type> property of every node in the list.

=cut

sub node_types { return map {$_->type} shift->get_nodes; }


=head2 get_variables

Get a list of variable names used in our template.

=cut

sub get_variables {
    my ($self) = @_;
    return map {$_->name} grep {$_->type eq 'variable'} map {$_->decompose}
        $self->get_nodes;
}


=head1 Alternative Constructors

These constructors build a new C<Judoon::Tmpl> object from simpler
representations.

=head2 new_from_data( [ \%node1, \%node2, ... ] )

Builds a new C<Judoon::Tmpl> from an arrayref of hashrefs, where each
hashref represents a node.  The hashrefs should each have a C<type>
key that specifies the type of node to be built, and the other keys
should reflect the other attributes of each particular node
type. e.g. a C<Text> node would look like:

 my $variable_node = { type => 'variable', name => 'foo_column' };
 my $formatted_text_node = {
     type => 'text', value => 'bar-text', formatting => ['bold'],
 };

 my $tmpl = Judoon::Tmpl->new_from_data([
     $variable_node, $formatted_text_node,
 ]);

=cut

sub new_from_data {
    my ($class, $nodelist) = @_;
    die "Don't call new_from_data() on an object" if (ref($class));
    die 'Argument to new_from_data() must be an arrayref'
        unless (ref($nodelist) eq 'ARRAY');

    my @nodes = map {$class->_new_node($_)} @$nodelist;
    return $class->new({nodes => \@nodes});
}


=head2 new_from_native( $json )

Builds a new C<Judoon::Tmpl> from its serialized representation. This
is just a wrapper around C<L</new_from_data>> that decodes the given
input, which is expected to be a vaid JSON string.

=cut

sub new_from_native {
    my ($class, $json) = @_;
    my $nodelist = from_json($json, $json_opts);
    return $class->new_from_data($nodelist);
}


=head2 new_from_jstmpl

Builds a new C<Judoon::Tmpl> object from a string that is a
jsrender.js -compatible template.  It uses C<L</_jstml_parser>> to
parse the string into a list of C<Judoon::Tmpl::Node::*> nodes.  It
dies on C<undef> input, and creates an empty template if given the
empty string.  We can't know the C<varstring_type> of a link
component (url or label) explicitly, so it calls the
C<_varstring_type> method to guess.

=cut

sub new_from_jstmpl {
    my ($class, $jstmpl) = @_;
    die "Don't call new_from_jstmpl() on an object" if (ref($class));

    die "Cannot parse undef input as JQueryTemplate"
        if (not defined $jstmpl);
    return $class->new_from_data([]) if ($jstmpl eq '');
    die "Cannot parse $jstmpl as JQueryTemplate, which shouldn't be possible"
        if ($jstmpl !~ $class->_jstmpl_parser());

    my @new_nodes;
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
                        varstring_type => $class->_varstring_type($segs->{url}),
                        %{$segs->{url}},
                    },
                    label => {
                        type           => 'varstring',
                        varstring_type => $class->_varstring_type($segs->{label}),
                        %{$segs->{label}},
                    },
                };
            }
        }

        push @new_nodes, $jnode;
    }

    return $class->new_from_data(\@new_nodes);
}


=head1 Template Representations

These methods control the output representation of our template.

=head2 to_data

Output our template as an arrayref of hashref.  Each hashref
represents a node.

=cut

sub to_data {
    my ($self) = @_;
    my @node_data = map {my $h = $_->pack; delete $h->{__CLASS__}; $h}
        $self->get_nodes;
    #delete class recursively
    return \@node_data;
}


=head2 to_native

Output our template as a serialized data structure. This method calls
C<L</to_data>> and JSON-encodes the output.

=cut

sub to_native {
    my ($self) = @_;
    return to_json($self->to_data, $json_opts);
}


=head2 to_jstmpl

Output our template as a jsrender.js-compatible template.

=cut

sub to_jstmpl {
    my ($self) = @_;

    my @objects = $self->get_nodes;
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


=head1 Utility Methods

=head2 _new_node( \%node )

Constructs and returns a new C<Judoon::Tmpl::Node::*> object based on
the C<type> key of C<%node>.

=cut

sub _new_node {
    my ($class, $node) = @_;
    die 'argument to _new_node() must be a hashref'
        unless (ref($node) eq 'HASH');

    my %node_type_to_class = (
        text => 'Text', variable => 'Variable',
        newline => 'Newline', link => 'Link',
        varstring => 'VarString',
    );

    my $node_class = $node_type_to_class{$node->{type}}
        or die 'Unrecognized node type: ' . $node->{type};
    $node_class = 'Judoon::Tmpl::Node::' . $node_class;
    return $node_class->new($node);
}


=head2 _varstring_type( \%varstring )

The C<_varstring_type> method takes a varstring struct and attempts to
guess its type based upon the presence of non-empty C<variable_segments>.

=cut

sub _varstring_type {
    my ($class, $varstring) = @_;
    return (exists($varstring->{variable_segments})
        && grep {m/\S/} @{$varstring->{variable_segments}})
            ? 'variable' : 'static';
}


=head2 _jstmpl_parser

Returns a L<Regexp::Grammars>-based parser regex for parsing
javascript templates.

=cut

sub _jstmpl_parser {
    my ($class) = @_;

    my $parser = do {
        # require Regexp::Grammars;
        # Regexp::Grammars->import();
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


1;
__END__
