package Judoon::Tmpl::Translator::Dialect::JQueryTemplate;

use autodie;
use Moose;
use namespace::autoclean;

with 'Judoon::Tmpl::Translator::Dialect';

use Data::Printer;
use Method::Signatures;


method parse($input) {

}

method produce(\@native_objects) {
    warn "Nodes is: " . p(@native_objects);
    my $template = q{};
    for my $node (@native_objects) {
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


__PACKAGE__->meta->make_immutable;

1;
__END__
