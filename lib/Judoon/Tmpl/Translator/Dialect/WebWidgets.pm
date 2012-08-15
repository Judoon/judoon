package Judoon::Tmpl::Translator::Dialect::WebWidgets;

use Moo;

with 'Judoon::Tmpl::Translator::Dialect';


use HTML::TreeBuilder;
use Judoon::Tmpl::Factory;
use Method::Signatures;
use Template;

has tt => (is => 'lazy',); # isa => 'Template'
sub _build_tt { return Template->new; }


method parse($input) {
    $input //= '';
    my $root = HTML::TreeBuilder->new_from_content($input);
    my @widgets = $root->look_down(qw(_tag div class), qr/widget-object/);
    my @nodes = $self->munge_widgets(\@widgets);
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
    my $option = $select->look_down(qw(_tag option selected), qr/^\S/);
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
        my ($link_field_type) = $input_classes =~ m/widget-link-([a-z0-9\-]+)/g;
        $link_props{$link_field_type} = $input->attr('value') if ($link_field_type);
        if (my @formats = ($input_classes =~ m/widget-formatting-(\w+)/g)) {
            @formatting = @formats;
        }
    }

    my %link_args;
    for my $component (qw(url label)) {
        $link_args{$component} = {
            varstring_type => $link_props{"${component}-type"},
            accession      => $link_props{"${component}-accession"} || '',
        };

        for my $segtype (qw(text variable)) {
            my @segs = map {$link_props{"${component}-${segtype}-segment-$_"}}
                sort {$a <=> $b}
                    grep {defined}
                        map {m/$component\-$segtype\-segment\-(\d+)/}
                            keys %link_props;
            $link_args{$component}->{"${segtype}_segments"} = @segs ? \@segs : [q{}];
        }
    }

    return new_link_node({formatting => [@formatting], %link_args,});
}

method process_newline($widget) {
    return new_newline_node();
}



# producer methods

has produce_text_tmpl => (is => 'lazy',); # isa => 'Str'
sub _build_produce_text_tmpl {
    return <<'EOT';
<div class="widget-object widget-type-text widget-inline input-append dropdown">
  <input type="text" class="input-medium widget-format-target widget-format-sibling [% FOREACH format IN node.formatting %]widget-formatting-[% format %] [% END %]" placeholder="Type text here" [% IF node %]value="[% node.value %]"[% END %] />
</div>
EOT
}


has produce_variable_tmpl => (is => 'lazy',); # isa => 'Str'
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
<div class="widget-object widget-type-data widget-inline input-append dropdown">
  <select class="widget-format-target widget-format-sibling [% FOREACH format IN node.formatting %]widget-formatting-[% format %] [% END %]">
    <option [% IF node %]value="[% node.name %]" selected="selected"[% END %]></option>
  </select>
</div>
EOT
}


has produce_link_tmpl => (is => 'lazy',); # isa => 'Str',
sub _build_produce_link_tmpl {
    return <<'EOT';
[% IF ! node %][% placeholder_text = 'Click here to edit link' %][% ELSE %]
[% display_url   = node.url.text_segments.0 _ (node.url.variable_segments.0 ? node.url.variable_segments.0 : '') %]
[% display_label = node.label.text_segments.0 _ (node.label.variable_segments.0 ? node.label.variable_segments.0 : '') %]
[% placeholder_text = "Link to: " _ (display_url == display_label ? display_url : display_label _ ' (' _ display_url _ ')') %]
<!-- display_url is [% display_url %] -->
<!-- display_label is [% display_label %] -->
[% END %]
<div class="widget-object widget-type-link widget-inline input-append dropdown">
  <input type="text" class="input-medium disabled btn-edit-link widget-format-target widget-format-sibling" placeholder="[% placeholder_text %]" />
  [% FOREACH component IN ['url', 'label'] %]
  <input type="hidden" class="widget-link-[% component %]-accession" value="[% node.$component.accession %]">
  <input type="hidden" class="widget-link-[% component %]-type"      value="[% node.$component.varstring_type %]">
  [% FOREACH segtype IN ['text', 'variable'] %][% seg_method = segtype _ '_segments' %][% FOREACH seg IN node.$component.$seg_method %]
  <input type="hidden" class="widget-link-[% component %]-[% segtype %]-segment-[% loop.count %]" value="[% seg %]">
  [% END %][% END %]
  [% END %]
</div>
EOT
}


has produce_newline_tmpl => (is => 'lazy',); # isa => 'Str',
sub _build_produce_newline_tmpl {
    return <<'EOT';
<div class="widget-object widget-type-newline-icon"><i class="icon-arrow-down"></i></div>
<div class="widget-object widget-type-newline"></div>
EOT
}


1;

__END__

