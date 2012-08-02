package Catalyst::Controller::DBIC::API::Request::Chained;

use Moose::Role;
use MooseX::Types::Moose(':all');
use MooseX::Types::Structured('Tuple');
use Catalyst::Controller::DBIC::API::Types(':all');
use namespace::autoclean;

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
