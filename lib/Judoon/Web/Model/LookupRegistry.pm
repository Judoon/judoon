package Judoon::Web::Model::LookupRegistry;

use Moose;
use namespace::autoclean;
extends 'Catalyst::Model::Factory::PerRequest';

__PACKAGE__->config( class => 'Judoon::LookupRegistry' );


sub prepare_arguments {
    my ($self, $c) = @_;
    return {
        schema => $c->model('User')->schema,
        user   => $c->user->get_object,
    };
}

__PACKAGE__->meta->make_immutable;
1;
__END__

=pod

=encoding utf8

=head1 NAME

Judoon::Web::Model::LookupRegistry - Catalyst Adaptor Model for Judoon::LookupRegistry

=head1 SYNOPSIS

See L<Judoon::Web>

=head1 DESCRIPTION

L<Catalyst::Model::Adaptor> Model wrapping L<Judoon::LookupRegistry>

=cut
