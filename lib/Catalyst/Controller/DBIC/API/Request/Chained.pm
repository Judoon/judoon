package Catalyst::Controller::DBIC::API::Request::Chained;

=pod

=encoding utf-8

=head1 NAME

Catalyst::Controller::DBIC::API::Request::Chained

=head1 DESCRIPTION

This role is similar to L</Catalyst::Controller::DBIC::API::Request>.
It applies to the L</Catalyst::Request> object to add an attribute for
storing previously chained objects.

=cut

use Moose::Role;
use MooseX::Types::Moose(':all');
use MooseX::Types::Structured('Tuple');
use Catalyst::Controller::DBIC::API::Types(':all');
use namespace::autoclean;


=head1 Attributes

=head2 chained_objects

An ArrayRef of the previously chained objects.

=cut

has chained_objects => (
    is => 'ro',
    isa => ArrayRef[ Tuple[ Object, Maybe[HashRef] ] ],
    traits => [ 'Array' ],
    default => sub { [] },
    handles => {
        all_chained_objects => 'elements',
        add_chained_object => 'push',
        count_chained_objects => 'count',
        has_chained_objects => 'count',
        clear_chained_objects => 'clear',
        get_chained_object => 'get',
    },
);


1;
__END__
