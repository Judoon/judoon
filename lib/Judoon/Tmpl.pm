package Judoon::Tmpl;

=pod

=for stopwords VarString

=encoding utf-8

=head1 NAME

Judoon::Tmpl - Object representing a template

=head1 SYNOPSIS

 use Judoon::Tmpl;

 my $template   = Judoon::Tmpl->new_from_jstmpl('foo{{bar}}baz');
 my @variables  = $template->get_variables(); # 'bar'
 my $serialized = $template->to_native;
 my $javascript = $template->to_jstmpl;

=head1 DESCRIPTION

C<Judoon::Tmpl> is an object that represents a template.

=cut

use Data::Visitor::Callback;
use HTML::TreeBuilder;
use JSON::MaybeXS;
use Judoon::Error::Devel;
use Judoon::Error::Devel::Arguments;
use Judoon::Error::Input;
use Judoon::Tmpl::Node::Text;
use Judoon::Tmpl::Node::Variable;
use Judoon::Tmpl::Node::Link;
use Judoon::Tmpl::Node::Image;
use Judoon::Tmpl::Node::Newline;
use Judoon::Tmpl::Node::VarString;
use MooX::Types::MooseLike::Base qw(ArrayRef ConsumerOf RegexpRef InstanceOf);
use Params::Validate qw(:all);

use Moo;
use feature ':5.10';
use namespace::clean;


=head1 Attributes

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


=head2 Node methods

These are convenience methods for getting / querying the node list.

=head3 get_nodes

Returns the list of nodes

=cut

sub get_nodes  { return @{ shift->nodes }; }


=head3 node_count

Returns the number of nodes

=cut

sub node_count { return scalar shift->get_nodes; }


=head3 node_types

Returns a list of the C<type> property of every node in the list.

=cut

sub node_types { return map {$_->type} shift->get_nodes; }


=head3 get_variables

Get a list of variable names used in our template.

=cut

sub get_variables {
    my ($self) = @_;
    return map {$_->name} grep {$_->type eq 'variable'} map {$_->decompose}
        $self->get_nodes;
}


=head2 data_scrubber / _build_data_scrubber

A C<L<Data::Visitor::Callback>> object responsible for scrubbing
unwanted keys from the C<L</to_data>> representation of the
object. Currently, this just deletes the C<__CLASS__> keys added by
C<L<MooseX::Storage>>'s C<pack()> method.

=cut

has data_scrubber => (is => 'lazy', isa => InstanceOf('Data::Visitor::Callback'),);
sub _build_data_scrubber {
    return Data::Visitor::Callback->new(
        hash => sub {
            my ($visitor, $data) = @_;
            delete $data->{__CLASS__};
            return $data;
        },
    );
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
    Judoon::Error::Devel->throw({
        message => "Don't call new_from_data() on an object",
    }) if (ref($class));
    Judoon::Error::Devel::Arguments->throw({
        message  => 'Argument to new_from_data() must be an arrayref',
        expected => 'arrayref',
        got      => ref($nodelist),
    }) unless (ref($nodelist) eq 'ARRAY');

    my @nodes = map {$class->_new_node($_)} @$nodelist;
    return $class->new({nodes => \@nodes});
}


=head2 new_from_native( $json )

Builds a new C<Judoon::Tmpl> from its serialized representation. This
is just a wrapper around C<L</new_from_data>> that decodes the given
input, which is expected to be a valid utf8-encoded JSON string.

=cut

sub new_from_native {
    my ($class, $json) = validate_pos(
        @_, {type => SCALAR,}, {type => SCALAR,},
    );
    my $nodelist = decode_json($json);
    return $class->new_from_data($nodelist);
}


=head2 new_from_jstmpl

Builds a new C<Judoon::Tmpl> object from a string that is a
Handlebars.js -compatible template.  It calls C<L</_parse_js>> to
parse the string into a list of C<Judoon::Tmpl::Node::*> nodes.  It
dies on C<undef> input, and creates an empty template if given the
empty string.

=cut

sub new_from_jstmpl {
    my ($class, $jstmpl) = @_;
    Judoon::Error::Devel->throw({
        message => "Don't call new_from_jstmpl() on an object",
    }) if (ref($class));
    Judoon::Error::Devel::Arguments->throw({
        message  => "Cannot parse undef input as javascript template",
        expected => 'string',
        got      => 'undef',
    }) if (not defined $jstmpl);

    return $class->new_from_data(
        $jstmpl eq '' ? [] : $class->_parse_js($jstmpl)
    );
}


=head1 Template Representations

These methods control the output representation of our template.

=head2 to_data

Output our template as an arrayref of hashref.  Each hashref
represents a node.

=cut

sub to_data {
    my ($self) = @_;
    my @node_data = map {$_->pack;} $self->get_nodes;
    $self->data_scrubber->visit(\@node_data);
    return \@node_data;
}


=head2 to_native()

Output our template as a serialized data structure. This method calls
C<L</to_data>> and JSON+utf8-encodes the output.

=cut

sub to_native {
    my ($self) = @_;
    return encode_json($self->to_data);
}


=head2 to_jstmpl

Output our template as a Handlebars.js-compatible template.

=cut

sub to_jstmpl {
    my ($self) = @_;
    return $self->_nodes_to_jstmpl($self->get_nodes);
}

# supported formatting tags
my %format_tags = (
    bold   => [qw(<strong> </strong>)],
    italic => [qw(<em> </em>)],
);


=head3 _nodes_to_jstmpl( \@nodes )

Private method for recursively rendering nodes to the Handlebars
javascript template dialect.

=cut

sub _nodes_to_jstmpl {
    my ($self, @nodes) = @_;

    my $template = q{};
    while (my $node = shift @nodes) {
        my @text;
        if ($node->does('Judoon::Tmpl::Node::Role::Composite')) {
            push @text, $self->_nodes_to_jstmpl($node->decompose());
        }
        else {
            push @text, $node->type eq 'text'     ? $node->value
                      : $node->type eq 'variable' ? '{{' . $node->name . '}}'
                      : Judoon::Error::Devel->throw({
                            message => "Unrecognized node type! " . $node->type,
                        });
        }

        if (my @formats = @{$node->formatting}) {
            for my $format (@formats) {
                my $format_tags = $format_tags{$format};
                @text = ($format_tags->[0], @text, $format_tags->[1]);
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
    Judoon::Error::Devel::Arguments->throw({
        message  => 'Argument to _new_node() must be a hashref',
        expected => 'hashref',
        got      => ref($node),
    }) unless (ref($node) eq 'HASH');

    my %node_type_to_class = (
        text => 'Text', variable => 'Variable',
        newline => 'Newline', link => 'Link', image => 'Image',
        varstring => 'VarString',
    );

    my $node_class = $node_type_to_class{$node->{type}}
        or Judoon::Error::Devel->throw({
            message => "Unrecognized node type! " . $node->{type},
        });
    $node_class = 'Judoon::Tmpl::Node::' . $node_class;
    return $node_class->new($node);
}


=head1 javascript template parsing methods

These are private methods used to parse our html/javascript templates

=head2 _parse_js( $js_template )

Parse a javascript template using L<HTML::TreeBuilder>.  Returns a
list of data structs suitable for passing to C<L</new_from_data>>.

=cut

sub _parse_js {
    my ($class, $jstmpl) = @_;
    my $root = HTML::TreeBuilder->new_from_content($jstmpl);
    my ($head, $body) = $root->content_list;
    my @nodelist = $class->_get_nodes_from_tree($body);
    return \@nodelist;
}


=head2 _get_nodes_from_tree( $html_element )

Takes an C<L<HTML::Element>> and returns a list of nodes based on its
children.  This is where the magic happens!

=cut

sub _get_nodes_from_tree {
    my ($class, $current_element) = @_;

    my @nodelist;
    my @elements = $current_element->content_list;
    for my $element (@elements) {

        if (not ref $element) { # text and variables
            my @nodes = $class->_parse_literal($element);
            while (@nodes) {
                my $text = shift @nodes;
                push @nodelist, {type => 'text', value => $text}
                    if ($text ne '');
                my $variable = shift @nodes;
                push @nodelist, {type => 'variable', name => $variable}
                    if ($variable);
            }
        }
        elsif ($element->tag eq 'a') { # add Link node
            my $url_literal   = $element->attr('href');
            my @label_content = $element->content_list;

            Judoon::Error::Input->throw({
                message => 'html tags found inside <a></a>',
                got     => $element->as_HTML,
            }) if (@label_content > 1);

            my $label_literal = $label_content[0];
            my $link_node = {
                type  => 'link',
                url   => { $class->_build_varstring($url_literal)   },
                label => { $class->_build_varstring($label_literal) },
            };
            push @nodelist, $link_node;
        }
        elsif ($element->tag eq 'img') { # add Image node
            my $url_literal   = $element->attr('src');
            my $image_node = {
                type => 'image',
                url  => { $class->_build_varstring($url_literal)   },
            };
            push @nodelist, $image_node;
        }
        elsif ($element->tag eq 'br') { # add Newline node
            push @nodelist, {type => 'newline'};
        }
        elsif ($element->tag eq 'strong') { # mark content as bold
            push @nodelist, $class->_apply_formatting_to_nodes(
                'bold', $class->_get_nodes_from_tree($element)
            );
        }
        elsif ($element->tag eq 'em') { # mark content as italic
            push @nodelist, $class->_apply_formatting_to_nodes(
                'italic', $class->_get_nodes_from_tree($element)
            );
        }
        else {
            Judoon::Error::Input->throw({
                message => 'Unsupported tag type in the javascript template',
                got     => $element->tag,
            });
        }
    }

    return @nodelist;
}


=head2 _apply_formatting_to_nodes( $format, @nodes )

Take a formatting code (currently one of 'bold' or 'italic') and push
it onto the given nodes formatting list, creating the list if not
already present.

=cut

sub _apply_formatting_to_nodes {
    my ($class, $format, @nodes) = @_;
    for my $node (@nodes) {
        $node->{formatting} ||= [];
        push @{$node->{formatting}}, $format;
    }
    return @nodes;
}


=head2 _parse_literal( $literal )

Turn a regular text string into a list of text values and variable
names.  The even-indexed elements of the list (i.e. 0,2,4,etc.) will
always be text values, and the odd elements will always be variable
names.  If the literal string begins with a variable (such as
"{{bar}}"), the first element of the list will be the empty string.

 $class->_parse_literal('foo{{bar}}baz');
 # returns ('foo','bar','baz')

 $class->_parse_literal('{{bar}}baz');
 # returns ('','bar','baz')

=cut

sub _parse_literal {
    my ($class, $literal_string) = @_;
    return split /{{([\w_]+)}}/, $literal_string;
}


=head2 _build_varstring( $literal )

Build a VarString struct. Guess at varstring_type.

=cut

sub _build_varstring {
    my ($class, $literal_string) = @_;

    my %varstring = (
        type              => 'varstring',
        text_segments     => [],
        variable_segments => [],
    );

    my @segs = $class->_parse_literal($literal_string);
    while (@segs) {
        push @{$varstring{text_segments}}, shift(@segs);
        push @{$varstring{variable_segments}}, (shift(@segs) // '');
    }

    $varstring{varstring_type}
        = (grep {m/\S/} @{$varstring{variable_segments}})
            ? 'variable' : 'static';
    return %varstring;
}



1;
__END__
