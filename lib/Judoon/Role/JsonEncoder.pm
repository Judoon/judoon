package Judoon::Role::JsonEncoder;

use Moo::Role;

use JSON::MaybeXS qw(JSON);

has _json_encoder => (
   is => 'ro',
   lazy => 1,
   builder => '_build_json_encoder',
   handles => {
      encode_json => 'encode',
      decode_json => 'decode',
   },
);

sub _build_json_encoder { JSON->new->utf8(1); }


1;
__END__
