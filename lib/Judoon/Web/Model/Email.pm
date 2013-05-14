package Judoon::Web::Model::Email;

=pod

=encoding utf8

=head1 NAME

Judoon::Web::Model::Email - Catalyst Adaptor Model for Judoon::Email

=head1 DESCRIPTION

L<Catalyst::Model::Adaptor> Model wrapping L<Judoon::Email>

=cut

use Moose;
use namespace::autoclean;
extends 'Catalyst::Model::Adaptor';

__PACKAGE__->config(
    class => 'Judoon::Email',
    args  => {kit_path => 'root/src/email_kits',},
 );

__PACKAGE__->meta->make_immutable;
1;
__END__
