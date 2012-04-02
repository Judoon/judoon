package Judoon::Tmpl::Translator::Dialect::WebWidgets;

use Moose;
use namespace::autoclean;

with 'Judoon::Tmpl::Translator::Dialect';


use Data::Printer;
use HTML::TreeBuilder;
use Judoon::Tmpl::Factory;
use Method::Signatures;
use Template;

has tt => (is => 'ro', isa => 'Template', lazy_build => 1);
sub _build_tt { return Template->new; }


method parse($input) {
    my $root = HTML::TreeBuilder->new_from_content($input);
    my @widgets = $root->look_down(qw(_tag div class), qr/widget-object/);
    # warn "Widgets is: " . p(@widgets);
    my @nodes = $self->munge_widgets(\@widgets);
    # warn "Nodes is: " . p(@nodes);
    return @nodes;
}

method produce(\@nodes) {

    my ($count, $output) = 0;
    for my $node (@nodes) {
        my $method = 'produce_' . $node->type . '_tmpl';
        my $node_tmpl = $self->$method();
        my $node_output;
        $self->tt->process(\$node_tmpl, {node => $node}, \$node_output, binmode => ':utf8')
            or die 'Unable to process template: ' . $self->tt->error;
        $output .= $node_output;
    }

    return $output;
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



# producer methods

has produce_text_tmpl => (is => 'ro', isa => 'Str', lazy_build => 1);
sub _build_produce_text_tmpl {
    return <<'EOT';
<div class="widget-object widget-type-text widget-inline btn-group">
  <input type="text" class="inner-small span2 w-dropdown widget-format-target widget-format-sibling [% FOREACH format IN node.formatting %]widget-formatting-[% format %] [% END %]" placeholder="Type text here" [% IF node %]value="[% node.value %]"[% END %] />
</div>
EOT
}


has produce_variable_tmpl => (is => 'ro', isa => 'Str', lazy_build => 1);
sub _build_produce_variable_tmpl {
# empty
#  <div class="widget-object widget-type-data widget-inline btn-group">
#    <select class="w-dropdown widget-format-target">
#      [% FOREACH column IN ds_column.list %]
#      <option value="[% column.shortname %]">{[% column.name | html %]}</option>
#      [% END %]
#    </select>[% INCLUDE format_dropdown %]
#  </div>
# filled
#  <div id="widget_id_1" class="widget-object widget-type-data widget-inline btn-group">
#    <select id="widget_format_id_1" class="w-dropdown widget-format-target">
#      <option value="gene_symbol">{Gene Symbol}</option>
#      <option value="protein_name" selected="selected">{Protein Name}</option>
#      <option value="flybase_link">{Flybase Link}</option>
#      <option value="fold_change">{Fold Change}</option>
#      <option value="proposed_function">{Proposed Function}</option>
#      <option value="nearest_mammalian_homolog">{Nearest mammalian homolog}</option>
#      <option value="unigene__human_homolog_">{Unigene (human homolog)}</option>
#    </select>
#  </div>
    return <<'EOT';
<div class="widget-object widget-type-data widget-inline btn-group">
  <select class="w-dropdown widget-format-target widget-format-sibling [% FOREACH format IN node.formatting %]widget-formatting-[% format %] [% END %]">
    <option [% IF node %]value="[% node.name %]" selected="selected"[% END %]></option>
  </select>
</div>
EOT
}


has produce_link_tmpl => (is => 'ro', isa => 'Str', lazy_build => 1);
sub _build_produce_link_tmpl {
    return <<'EOT';
<div class="widget-object widget-type-link widget-inline btn-group">
  <a class="btn btn-edit-link widget-format-sibling"><i class="icon-pencil"></i> Edit link</a>
  <input type="hidden" class="widget-link-url-source widget-format-target" value="">
  <input type="hidden" class="widget-link-url-site"      value="">
  <input type="hidden" class="widget-link-url-prefix"    value="">
  <input type="hidden" class="widget-link-url-postfix"   value="">
  <input type="hidden" class="widget-link-url-datafield" value="">
  <input type="hidden" class="widget-link-label-type"  value="[% node.label_type %]">
  <input type="hidden" class="widget-link-label-value" value="[% node.label_value %]">
</div>
EOT
}


has produce_newline_tmpl => (is => 'ro', isa => 'Str', lazy_build => 1);
sub _build_produce_newline_tmpl {
    return <<'EOT';
<div class="widget-object widget-type-newline-icon"><i class="icon-arrow-down"></i></div>
<div class="widget-object widget-type-newline"></div>
EOT
}


__PACKAGE__->meta->make_immutable;

1;

__END__

