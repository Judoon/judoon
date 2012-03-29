package Judoon::Tmpl::Translator::Dialect;

use Moose::Role;

use Judoon::Tmpl::Factory;

requires 'parse';
requires 'produce';

1;
__END__
