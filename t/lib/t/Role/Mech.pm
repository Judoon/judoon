package t::Role::Mech;

use Test::Roo::Role;

use Judoon::Web ();
use MooX::Types::MooseLike::Base qw(InstanceOf);
use Test::WWW::Mechanize::Catalyst;

requires 'schema';

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
