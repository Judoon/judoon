package t::Role::WebApp;

use Test::Roo::Role;

requires 'mech';

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
