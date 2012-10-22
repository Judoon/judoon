package Judoon::Tmpl;

use Moo;
use MooX::Types::MooseLike::Base qw(ArrayRef ConsumerOf InstanceOf);

use Judoon::Tmpl::Translator;

has nodes => (is => 'lazy', isa => ArrayRef[ConsumerOf('Judoon::Tmpl::Node::Base')],);
sub _build_nodes { return []; }

has translator => (is => 'lazy', isa => InstanceOf('Judoon::Tmpl::Translator'),);
sub _build_translator { return Judoon::Tmpl::Translator->new; }





1;
__END__
