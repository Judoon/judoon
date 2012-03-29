package Judoon::Tmpl::Translator::Dialect::JQueryTemplate;

use Moose;
use namespace::autoclean;

with 'Judoon::Tmpl::Translator::Dialect';

use Data::Printer;
use Method::Signatures;


method parse($input) { ... };

method produce(\@native_objects) {

    my $template = q{};
    while (my $node = shift @native_objects) {

        if ($node->meta->does_role('Judoon::Tmpl::Node::Role::Composite')) {
            unshift @native_objects, $node->decompose();
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


__PACKAGE__->meta->make_immutable;

1;
__END__
