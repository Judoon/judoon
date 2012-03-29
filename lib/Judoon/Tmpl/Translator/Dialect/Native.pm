package Judoon::Tmpl::Translator::Dialect::Native;

use Moose;
use namespace::autoclean;

with 'Judoon::Tmpl::Translator::Dialect';

use Data::Printer;
use JSON qw(encode_json decode_json);
use Method::Signatures;


method parse($input) {
    my $native_struct = decode_json($input);

    my @nodes;
    for my $struct (@$native_struct) {
        push @nodes, {};
    }
    return @nodes;
}

method produce(\@native_objects) {

}


__PACKAGE__->meta->make_immutable;

1;
__END__
