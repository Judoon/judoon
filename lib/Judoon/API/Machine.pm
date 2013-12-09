package Judoon::API::Machine;

use Moo;
extends 'Web::Machine';
use namespace::clean;

use Web::Machine::I18N::en;
$Web::Machine::I18N::en::Lexicon{422} = 'Unprocessable Entity';

1;
__END__

=pod

=encoding utf8

=head1 NAME

Judoon::API::Machine - Web::Machine-based REST interface to Judoon

=head1 DESCRIPTION

See L</Web::Machine>.

=cut