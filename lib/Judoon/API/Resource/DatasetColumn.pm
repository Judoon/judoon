package Judoon::API::Resource::DatasetColumn;

use Moo;
use namespace::clean;

extends 'Web::Machine::Resource';
with 'Judoon::Role::JsonEncoder';
with 'Judoon::API::Resource::Role::Item';

sub update_allows { return qw(data_type); }
sub update_ignore { return qw(created modified sample_data); }
sub update_valid  { return {data_type => qr/^\w+$/}; }
with 'Judoon::API::Resource::Role::ValidateParams';

sub allowed_methods {
    my ($self) = @_;
     return [
        qw(GET HEAD),
        ( $_[0]->writable ) ? (qw(PUT)) : ()
    ];
}


1;
__END__

=pod

=encoding utf8

=head1 NAME

Judoon::API::Resource::DatasetColumn - An individual DatasetColumn

=head1 DESCRIPTION

See L</Web::Machine::Resource>.

=head1 METHODS

=head2 update_allows()

List of updatable parameters.

=cut
