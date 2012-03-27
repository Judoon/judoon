package Judoon::Template::Translator;

use version; our $VERSION = '0.0.1';
use autodie;
use open qw( :encoding(UTF-8) :std );

use Moose;
use namespace::autoclean;

use Data::Printer;
use HTML::TreeBuilder;
use Method::Signatures;

has params => (is => 'rw');

method translate($html) {
    my $root = HTML::TreeBuilder->new_from_content($html);

    my @nodes = $self->munge_widgets([
        $root->look_down(qw(_tag div class), qr/widget-object/)
    ]);

    my $template = $self->nodes_to_template(\@nodes);
    return $template;
}



method munge_widgets(\@widgets) {
    my @nodes;
    warn "Widgets is: " . p(@widgets);
    for my $widget (@widgets) {
        my $type = $self->get_widget_type($widget);
        next if $type eq 'newline-icon';

        my $method = "process_$type";
	push @nodes, $self->$method($widget);
    }
    warn "Nodes is: " . p(@nodes);
    return @nodes;
}


method get_widget_type($widget) {
    my $classes = $widget->attr('class');
    my ($type) = ($classes =~ m/widget-type-([\w\-]+)/);
    return $type;
}


method process_text($widget) {
    my ($input) = $widget->look_down(qw(_tag input type text));
    my $text = $input->attr('value');
    my $input_classes = $input->attr('class');
    my @formatting = ($input_classes =~ m/widget-formatting-(\w+)/g);
    return {type => 'text', value => $text, formatting => [@formatting]};
}


method process_data($widget) {
    my $select = $widget->look_down(qw(_tag select));
    warn "Select is: " . p($select);
    my $option = $select->look_down(qw(_tag option selected), qr/^\S/);
    warn "Option is: " . p($option);
    my $field  = $option->attr('value');
    my $field_classes = $select->attr('class');
    my @formatting = ($field_classes =~ m/widget-formatting-(\w+)/g);
    return {type => 'data', value => $field, formatting => [@formatting]};
}

method process_link($widget) {
    my (@inputs) = $widget->look_down(qw(_tag input type hidden));

    my (%link_props, @formatting);
    for my $input (@inputs) {
        my $input_classes = $input->attr('class');
        my ($link_field_type) = $input_classes =~ m/widget-link-([a-z\-]+)/g;
        $link_props{$link_field_type} = $input->attr('value');
        if (my @formats = ($input_classes =~ m/widget-formatting-(\w+)/g)) {
            @formatting = @formats;
        }
    }

    return {type => 'link', link_props => \%link_props, formatting => [@formatting]};
}

method process_newline($widget) {
    return {type => 'newline'};
}


method link_node_to_simple_nodes(\%link_props) {

    warn "LINK PROPS: " . p(%link_props);

    my @url_nodes = (
        {type => 'text', value => $link_props{'url-prefix'},    },
        {type => 'data', value => $link_props{'url-datafield'}, },
        {type => 'text', value => $link_props{'url-postfix'},   },
    );

    my @label_nodes = $link_props{'label-type'} eq 'url'     ? @url_nodes
                    : $link_props{'label-type'} eq 'static'  ? {type => 'text', value => $link_props{'label-value'}}
                    :    die 'unknown label-type';

    return (
        {type => 'text', value => '<a href="',},
        @url_nodes,
        {type => 'text', value => '">',},
        @label_nodes,
        {type => 'text', value => '</a>',},
    );
}

method nodes_to_template(\@nodes) {
    warn "Nodes is: " . p(@nodes);
    my $template = q{};
    for my $node (@nodes) {
        my @pieces = $node->{type} eq 'text'    ? ($node->{value})
                   : $node->{type} eq 'data'    ? ('{{=' . $node->{value} . '}}')
                   : $node->{type} eq 'link'    ? $self->nodes_to_template([$self->link_node_to_simple_nodes($node->{link_props})])
                   : $node->{type} eq 'newline' ? ('<br>')
                   :     die 'unsupported node type';

        if (exists $node->{formatting} && @{$node->{formatting}}) {
            if (grep {m/bold/} @{$node->{formatting}}) {
                @pieces = ('<strong>',@pieces,'</strong>');
            }
            if (grep {m/italic/} @{$node->{formatting}}) {
                @pieces = ('<em>',@pieces,'</em>');
            }
        }

        $template .= join '', @pieces;

    }
    return $template;
}


method to_widgets($template) {
    return $template;
}

__PACKAGE__->meta->make_immutable;

1;
__END__
