package t::Role::Mech;

=pod

=encoding utf-8

=head1 NAME

t::Role::Mech - a role for setting up a Test::WWW:Mechanize instance

=head1 DESCRIPTION

Provides a C<mech> attribute that is an instance of
L</Test::WWW::Mechanize::Catalyst> running L<Judoon::Web>. Requires a
C<schema> method that connects to a L<Judoon::Schema>.

=cut

use Judoon::Web ();
use MooX::Types::MooseLike::Base qw(InstanceOf);
use Test::WWW::Mechanize::Catalyst;

use Test::Roo::Role;

requires 'schema';

=head1 ATTRIBUTES

=head2 mech / _build_mech

An instance of L</Test::WWW::Machanize::Catalyst> connected to a
running L<Judoon::Web>.

=cut

has mech => (
    is => 'lazy',
    isa => InstanceOf['Test::WWW::Mechanize::Catalyst'],
);
sub _build_mech {
    my ($self) = @_;

    $ENV{PLACK_ENV} = 'testsuite';
    Judoon::Web->model('User')->schema($self->schema);
    return Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'Judoon::Web');
}


1;
__END__
