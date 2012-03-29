package Judoon::Tmpl::Translator::Dialect;

use Moose::Role;

use Judoon::Tmpl::Factory;

requires 'parse';
requires 'produce';

has factory => (
    is => 'ro',
    isa => 'Judoon::Tmpl::Factory',
    lazy_build => 1,
);
sub _build_factory { return Judoon::Tmpl::Factory->new; }

1;
__END__
