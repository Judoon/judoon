package Judoon::Tmpl::Translator::Dialect::Native;

use Moo;

with 'Judoon::Tmpl::Translator::Dialect';

use Judoon::Tmpl::Factory;
use JSON qw(encode_json decode_json);
use Method::Signatures;


method parse($input) {
    my $native_struct = decode_json($input);
    return map {build_node($_)} @$native_struct;
}

method produce(\@native_objects) {
    my @output = map {$_->pack} @native_objects;
    return encode_json(\@output);
}


1;
__END__
