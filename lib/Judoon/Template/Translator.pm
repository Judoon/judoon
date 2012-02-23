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

method process_newline($widget) {
    return {type => 'newline'};
}


method nodes_to_template(\@nodes) {
    warn "Nodes is: " . p(@nodes);
    my $template = q{};
    for my $node (@nodes) {
        my @pieces = $node->{type} eq 'text'    ? ($node->{value})
                   : $node->{type} eq 'data'    ? ('{{' . $node->{value} . '}}')
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
