package Judoon::Tmpl::Translator::Dialect::WebWidgets;

use Moose;
use namespace::autoclean;

with 'Judoon::Tmpl::Translator::Dialect';

use Data::Printer;
use HTML::TreeBuilder;
use Method::Signatures;


method parse($input) {
    my $root = HTML::TreeBuilder->new_from_content($input);
    my @widgets = $root->look_down(qw(_tag div class), qr/widget-object/);
    warn "Widgets is: " . p(@widgets);
    my @nodes = $self->munge_widgets(\@widgets);
    warn "Nodes is: " . p(@nodes);
    return @nodes;
}

method produce(\@nodes) {
}


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
    return Judoon::Tmpl::Factory->build({
        type => 'text', value => $text, formatting => [@formatting]
    });
}


method process_data($widget) {
    my $select = $widget->look_down(qw(_tag select));
    warn "Select is: " . p($select);
    my $option = $select->look_down(qw(_tag option selected), qr/^\S/);
    warn "Option is: " . p($option);
    my $field  = $option->attr('value');
    my $field_classes = $select->attr('class');
    my @formatting = ($field_classes =~ m/widget-formatting-(\w+)/g);
    return $self->factory->build({
        type => 'data', value => $field, formatting => [@formatting],
    });
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

    return $self->factory->build({
        type => 'link', link_props => \%link_props, formatting => [@formatting]
    });
}

method process_newline($widget) {
    return $self->factory->build({type => 'newline'});
}


__PACKAGE__->meta->make_immutable;

1;
__END__
