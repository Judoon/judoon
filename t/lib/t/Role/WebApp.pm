package t::Role::WebApp;

=pod

=encoding utf-8

=head1 NAME

t::Role::WebApp - a role for interacting with the Judoon WebApp

=head1 DESCRIPTION

This role contains common interactions with a Judoon::Web instance
available through the C<mech> attribute.

=cut

use Test::Roo::Role;

requires 'mech';


=head1 METHODS

=head2 login( $username, $password )

Login to Judoon through the HTML web login form with the provided
credentials.

=head2 logout

Logout of Judoon via the standard web url.

=cut

sub logout {
    my ($self) = @_;
    $self->mech->get('/logout');
}

sub login {
    my ($self, $username, $userpass) = @_;

    $self->logout();
    $self->mech->get('/login');
    $self->mech->submit_form(
        form_name => 'login_form',
        fields => {
            username => $username,
            password => $userpass,
        },
    );
}


1;
__END__
