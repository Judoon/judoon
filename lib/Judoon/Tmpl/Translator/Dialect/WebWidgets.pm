package Judoon::Tmpl::Translator::Dialect::WebWidgets;

use Moose;
use namespace::autoclean;

with 'Judoon::Tmpl::Translator::Dialect';


use Data::Printer;
use HTML::TreeBuilder;
use Judoon::Tmpl::Factory;
use Method::Signatures;


method parse($input) {
    my $root = HTML::TreeBuilder->new_from_content($input);
    my @widgets = $root->look_down(qw(_tag div class), qr/widget-object/);
    # warn "Widgets is: " . p(@widgets);
    my @nodes = $self->munge_widgets(\@widgets);
    # warn "Nodes is: " . p(@nodes);
    return @nodes;
}

method produce(\@nodes) { ... }

method munge_widgets(\@widgets) {
    my @nodes;
    for my $widget (@widgets) {
        my $type = $self->get_widget_type($widget);
        next if $type eq 'newline-icon';

        my $method = "process_$type";
	push @nodes, $self->$method($widget);
    }
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
    return new_text_node({value => $text, formatting => [@formatting],});
}


method process_data($widget) {
    my $select = $widget->look_down(qw(_tag select));
    #warn "Select is: " . p($select);
    my $option = $select->look_down(qw(_tag option selected), qr/^\S/);
    #warn "Option is: " . p($option);
    my $field  = $option->attr('value');
    my $field_classes = $select->attr('class');
    my @formatting = ($field_classes =~ m/widget-formatting-(\w+)/g);
    return new_variable_node({name => $field, formatting => [@formatting],});
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

    my @fields = qw(url-site url-prefix url-postfix url-datafield label-type label-value);
    my %link_args = (
        uri_text_segments     => [$link_props{'url-prefix'}],
        uri_variable_segments => [$link_props{'url-datafield'}],
        label_type            => $link_props{'label-type'},
    );
    if ($link_props{'url-postfix'}) {
        push @{$link_args{text_segments}}, $link_props{'url-postfix'};
    }
    if ($link_props{'label-value'}) {
        $link_args{label_value} = $link_props{'label-value'};
    }

    return new_link_node({formatting => [@formatting], %link_args,});
}

method process_newline($widget) {
    return new_newline_node();
}


__PACKAGE__->meta->make_immutable;

1;
__END__
