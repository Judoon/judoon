package Judoon::Web::Controller::User;

=pod

=encoding utf8

=cut

use Moose;
use namespace::autoclean;

BEGIN { extends 'Judoon::Web::Controller'; }
with qw(Judoon::Web::Controller::Role::ExtractParams);

use Try::Tiny;


=head2 signup / signup_GET / signup_POST

Get/submit the new user signup page.

=cut

sub signup : Chained('/base') PathPart('signup') Args(0) :ActionClass('REST') {
    my ($self, $c) = @_;
    $c->stash->{template} = 'signup.tt2';
}
sub signup_GET {}
sub signup_POST {
    my ($self, $c) = @_;

    my $params = $c->req->params;
    my %user_params = $self->extract_params('user', $params);

    if ($user_params{password} ne $user_params{confirm_password}) {
        $c->stash->{error} = 'Passwords do not match!';
        $c->detach;
    }

    my $user;
    eval {
        $user = $c->model('User::User')->create_user(\%user_params);
    };
    if ($@) {
        $c->stash->{error} = $@;
        $c->detach;
    };

    $c->authenticate({
        username => $user_params{username},
        password => $user_params{password},
    });
    $c->user_exists(1);

    $self->go_here($c, '/rpc/dataset/list', [$user->username]);
    $c->detach;
}


=head2 settings

This is the base for all the /settings/* pages

=cut

sub settings : Chained('/edit') PathPart('settings') CaptureArgs(0) {
    my ($self, $c) = @_;
    $c->stash->{user}{object} = $c->user;
}


=head2 settings_view

Action for /settings/.  Redirects to /user/profile.

=cut

sub settings_view : Chained('settings') PathPart('') Args(0) {
    my ($self, $c) = @_;
    $self->go_here($c, '/user/profile');
    $c->detach;
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

    my $params = $c->req->params;
    my %user_params = $self->extract_params('user', $params);
    try {
        $c->user->update(\%user_params);
    }
    catch {
        $c->stash->{alert}{error} = "Unable to update profile: $@";
        $c->detach;
    };

    $c->stash->{alert}{success} = 'Your profile has been updated.';
}


=head2 password / password_GET / password_POST

The action for changing the users password.

=cut

sub password : Chained('settings') PathPart('password') Args(0) :ActionClass('REST') {
    my ($self, $c) = @_;
    $c->stash->{template} = 'settings/password.tt2';
}
sub password_GET {}
sub password_POST {
    my ($self, $c) = @_;

    my $params = $c->req->params;
    my $found = grep {$params->{$_}} qw(old_password new_password confirm_new_password);
    my $errmsg
        = $found != 3                                                ? 'something is missing?'
        : !$c->user->check_password($params->{old_password})         ? 'Your old password is incorrect'
        : $params->{new_password} ne $params->{confirm_new_password} ? 'Passwords do not match!'
        : !$c->model('User::User')->validate_password($params->{new_password}) ? 'Invalid password'
        :                                                               '';
    if ($errmsg) {
        $c->stash->{alert}{error} = $errmsg;
        $c->detach;
    }

    try {
        $c->user->change_password($params->{new_password});
    }
    catch {
        $c->stash->{alert}{error} = "Unable to change password: $_";
        $c->detach;
    };

    $c->stash->{alert}{success} = 'Your password has been updated.';
}


=head2 base / id /edit

Actions for managing user pages.  base is currently empty.  id pulls
the $username out of the URL.  edit is the user overview page

=cut

sub base : Chained('/base') PathPart('user') CaptureArgs(0) {}
sub id   : Chained('base')  PathPart('')   CaptureArgs(1) {
    my ($self, $c, $username) = @_;
    my $user = $c->model('User::User')->find({username => $username});
    if (not $user) {
        $c->forward('/default');
        $c->detach;
    }

    if ($c->user && $c->user->username eq $user->username) {
        $c->stash->{user}{is_owner} = 1;
    }

    $c->stash->{user}{id}     = $username;
    $c->stash->{user}{object} = $user;
}
sub edit : Chained('id') PathPart('') Args(0) {
    my ($self, $c) = @_;
    $c->stash->{template} = 'user/edit.tt2';

    if ($c->stash->{user}{is_owner}) {
        my @datasets = $c->stash->{user}{object}->datasets();
        $c->stash->{dataset}{list} = \@datasets;
        $c->stash->{page}{list}    = [map {$_->pages} @datasets];
    }
    else {
        my @datasets = $c->stash->{user}{object}->datasets_rs()->public();
        $c->stash->{dataset}{list} = \@datasets;
        $c->stash->{page}{list}    = [map {$_->pages_rs->public} @datasets];
    }
}


sub dataset_base : Chained('id') Pathart('dataset') Args(0) {}
sub dataset_id : Chained('dataset_base') PathPart('') CaptureArgs(1) {}
sub dataset : Chained('dataset_id') PathPart('') Args() {}
sub dataset_column : Chained('dataset') PathPart('column') Args() {}
sub dataset_data   : Chained('dataset') PathPart('data') Args() {}
sub dataset_page   : Chained('dataset') PathPart('page') Args() {}

sub page_base : Chained('id') Pathart('page') Args(0) {}
sub page_id : Chained('page_base') PathPart('') CaptureArgs(1) {}
sub page : Chained('page_id') PathPart('') Args() {}
sub page_delete  : Chained('page') PathPart('delete') Args() {}


__PACKAGE__->meta->make_immutable;

1;
__END__
