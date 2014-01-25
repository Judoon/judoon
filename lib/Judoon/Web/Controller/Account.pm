package Judoon::Web::Controller::Account;

=pod

=for stopwords account-centric

=encoding utf8

=head1 NAME

Judoon::Web::Controller::Account - account-centric actions (signup, settings, etc.)

=cut

use Moose;
use namespace::autoclean;

BEGIN { extends 'Judoon::Web::Controller'; }
with qw(
    Judoon::Web::Controller::Role::ExtractParams
);

use Email::Address;
use Safe::Isa;
use Try::Tiny;


=head1 ACTIONS

=head2 base

Base action for managing accounts.  Currently does nothing.

=cut

sub base : Chained('/base') PathPart('account') CaptureArgs(0) {}


=head2 list

Handle password-reset tokens, otherwise redirect to more useful pages.

=cut

sub list : Chained('base') PathPart('') Args(0) {
    my ($self, $c) = @_;

    if (my $token = $c->req->params->{value}) {
        my $token = $c->model('User::Token')->find_by_value($token);
        if (not $token) {
            $self->set_error($c, 'No action found for token');
            $self->go_here($c, '/login/login', {});
            $c->detach();
        }
        elsif ($token->is_expired) {
            $token->delete;
            $self->set_error($c, <<'ERRMSG');
Your password reset token has expired. Please request another one.
ERRMSG
            $self->go_here($c, '/account/resend_password', {});
            $c->detach();
        }
        else {
            $c->authenticate({id => $token->user->id}, 'password_reset');
            $self->go_here($c, '/account/password', {});
        }
    }
    elsif (my $user = $c->user) {
        $self->go_here($c, '/jsapp/user_view', [$user->get('username')]);
        $c->detach();
    }
    else {
        $self->go_here($c, '/login/login');
    }
}


=head2 signup / signup_GET / signup_POST

Get/submit the new user signup page.

=cut

sub signup : Chained('base') PathPart('signup') Args(0) :ActionClass('REST') {
    my ($self, $c) = @_;
    $c->stash->{template} = 'account/signup.tt2';
}
sub signup_GET {}
sub signup_POST {
    my ($self, $c) = @_;

    my $params = $c->req->params;
    my %user_params = $self->extract_params('user', $params);

    if ($user_params{password} ne $user_params{confirm_password}) {
        $c->stash->{alert}{error} = 'Passwords do not match!';
        delete @user_params{ qw(password confirm_password) };
        $c->stash(signup => \%user_params);
        $c->detach;
    }

    my $user;
    try {
        $user = $c->model('User::User')->create_user(\%user_params);
    }
    catch {
        my $e = $_;
        $e->$_DOES('Judoon::Error::Input')
            ? do {
                $self->set_error($c, $e->message);
                $c->flash(signup => \%user_params);
                $self->go_here($c, '/account/signup');
            }
            : $c->error($e);
        $c->detach();
    };

    $c->authenticate({
        username => $user_params{username},
        password => $user_params{password},
    });
    $c->user_exists(1);

    $self->go_here($c, '/jsapp/user_view', [$user->username]);
    $c->detach;
}



=head2 resend_password / resend_password_GET / resend_password_POST

User forgot their password? Send them a reminder email with a password
reset link.

=cut

sub resend_password : Chained('base') PathPart('password_reset') Args(0) ActionClass('REST') {
    my ($self, $c) = @_;
    if (my $user = $c->user) {
        $self->go_here($c, '/jsapp/user_view', [$user->get('username')]);
        $c->detach();
    }
}
sub resend_password_GET {
    my ($self, $c) = @_;
    $c->stash->{template} = 'account/resend_password.tt2';
}
sub resend_password_POST {
    my ($self, $c) = @_;

    my $params = $c->req->params;
    my $user;
    if (my $email = $params->{email_address}) {
        $user = $c->model('User::User')->email_exists($email);
    }
    elsif (my $username = $params->{username}) {
        $user = $c->model('User::User')->user_exists($username);
    }

    if (not $user) {
        $self->set_error(
            $c, q{Couldn't find an account with the given information.},
        );
        $self->go_here($c, '/account/resend_password');
        $c->detach();
    }

    my $token     = $user->new_reset_token;
    my $token_val = $token->value;
    my $reset_uri = $c->uri_for_action('/account/list', [], {value => $token_val});

    try {
        $c->model('Emailer')->send(
            $c->model('Email')->new_password_reset({
                reset_uri => $reset_uri,
            }),
            {to => $user->email_address, },
        );
    }
    catch {
        my ($e) = $_;
        $c->log->error($e);
        my $error = <<'EOE';
We are unable to send an email at the moment.  An admin has
been notified. Please try again later.
EOE
        $self->set_error($c, $error);
        $self->go_here($c, '/login/login');
        $c->detach;
    };


    $self->set_notice($c, q{An email has been sent to the email address associated with the account.});
    $self->go_here($c, '/login/login');
}


=head2 settings

This is the base for all the /settings/* pages

=cut

sub settings : Chained('/login/required') PathPart('settings') CaptureArgs(0) {
    my ($self, $c) = @_;
    $c->stash->{user}{object} = $c->user;
}


=head2 settings_view

Action for /settings/.  Displays list of available setting pages.

=cut

sub settings_view : Chained('settings') PathPart('') Args(0) {
    my ($self, $c) = @_;
    $c->stash->{template} = 'settings/view.tt2';
}


=head2 profile / profile_GET / profile_POST

This is where the user goes to change their profile (name, email,
phone, etc.)

=cut

sub profile : Chained('settings') PathPart('profile') Args(0) :ActionClass('REST') {
    my ($self, $c) = @_;
    $c->stash->{user}{object} = $c->user;
    $c->stash->{template} = 'settings/profile.tt2';
}
sub profile_GET {}
sub profile_POST {
    my ($self, $c) = @_;

    my $params      = $c->req->params;
    my %user_params = $self->extract_params('user', $params);
    my ($email)       = Email::Address->parse($user_params{email_address});
    my $user_rs     = $c->model('User::User');
    my $error;

    if (!$email) {
        $error = 'Invalid email address!';
    }
    elsif (my $other_user = $user_rs->email_exists($email->address)) {
        if ($other_user->username ne $c->user->username) {
            $error = 'This email is already being used by another user!';
        }
    }

    if ($error) {
        $c->stash->{alert}{error} = "Unable to update profile: $error";
        $c->stash->{user}{object} = \%user_params;
        $c->detach;
    }

    try {
        $user_params{email_address} = $email->address;
        $c->user->update(\%user_params);
    }
    catch {
        die $_;
    };

    $c->stash->{alert}{success} = 'Your profile has been updated.';
}


=head2 password / password_GET / password_POST

The action for changing the users password.

=cut

sub password : Chained('settings') PathPart('password') Args(0) :ActionClass('REST') {
    my ($self, $c) = @_;
    $c->stash->{is_reset} = $c->user_in_realm('password_reset') ? 1 : 0;
    $c->stash->{template} = 'settings/password.tt2';
}
sub password_GET {}
sub password_POST {
    my ($self, $c) = @_;

    my $params = $c->req->params;
    my $user   = $c->user;
    my $errmsg;

    if (not $c->user_in_realm('password_reset')) {
        # regular password change, must check old_password
        if (not $user->check_password($params->{old_password})) {
            $errmsg = 'Your old password is incorrect';
        }
    }

    $errmsg
        ||= not(grep {$params->{$_}} qw(new_password confirm_new_password))      ? 'New password must not be blank'
          : $params->{new_password} ne $params->{confirm_new_password}           ? 'Passwords do not match!'
          : !$c->model('User::User')->validate_password($params->{new_password}) ? 'Invalid password'
          :                                                                        '';
    if ($errmsg) {
        $c->stash->{alert}{error} = $errmsg;
        $c->detach;
    }

    try {
        $user->change_password($params->{new_password});
    }
    catch {
        $c->stash->{alert}{error} = "Unable to change password: $_";
        $c->detach;
    };

    if ($c->user_in_realm('password_reset')) {
        $user->tokens_rs->password_reset->delete;
    }

    $self->set_success($c, 'Your password has been updated.');
    $self->go_here($c, '/jsapp/user_view', [$user->username]);
}







__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 AUTHOR

Fitz ELLIOTT <felliott@fiskur.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by the Rector and Visitors of the
University of Virginia.

This is free software, licensed under:

 The Artistic License 2.0 (GPL Compatible)

=cut
