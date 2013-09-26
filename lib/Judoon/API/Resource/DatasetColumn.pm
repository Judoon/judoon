package Judoon::API::Resource::DatasetColumn;

use Moo;
use namespace::clean;

extends 'Web::Machine::Resource';
with 'Judoon::Role::JsonEncoder';
with 'Judoon::API::Resource::Role::Item';


1;
__END__

=pod

=encoding utf8

=head1 NAME

Judoon::API::Resource::DatasetColumn - An individual DatasetColumn

=head1 DESCRIPTION

See L</Web::Machine::Resource>.

=cut
