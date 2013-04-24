package Judoon::Web::Controller::User;

=pod

=for stopwords user-centric

=encoding utf8

=head1 NAME

Judoon::Web::Controller::User - user-centric actions (signup, settings, etc.)

=cut

use Moose;
use namespace::autoclean;

BEGIN { extends 'Judoon::Web::Controller'; }
with qw(
    Judoon::Web::Controller::Role::ExtractParams
);

use Email::Sender::Simple;
use Email::Simple;
use Safe::Isa;
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
        $c->stash->{alert}{error} = 'Passwords do not match!';
        $c->detach;
    }

    my $user;
    try {
        $user = $c->model('User::User')->create_user(\%user_params);
    }
    catch {
        my $e = $_;
        $e->$_DOES('Judoon::Error::Input')
            ? $self->set_error_and_redirect($c, $e->message, ['/user/signup'])
            : $c->error($e);
        $c->detach();
    };

    $c->authenticate({
        username => $user_params{username},
        password => $user_params{password},
    });
    $c->user_exists(1);

    $self->go_here($c, '/user/edit', [$user->username]);
    $c->detach;
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
    $c->stash->{is_reset} = $c->user_in_realm('password_reset') ? 1 : 0;
    $c->stash->{template} = 'settings/password.tt2';
}
sub password_GET {}
sub password_POST {
    my ($self, $c) = @_;

    my $params = $c->req->params;
    my $user   = $c->user;
    my $errmsg;
    my @reset_tokens;

    if ($c->user_in_realm('password_reset')) {

        @reset_tokens = $user->valid_reset_tokens;
        if (not @reset_tokens) {
            $c->user->logout;
            $self->set_error($c, <<'ERRMSG');
Your password reset token has expired. Please request another one.
ERRMSG
            $self->go_here($c, '/user/resend_password');
            $c->detach();
        }

    }
    else { # regular password change, must check old_password
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


    $_->delete for (@reset_tokens);

    $c->flash->{alert}{success} = 'Your password has been updated.';
    $self->go_here($c, '/user/edit', [$user->username]);
}


=head2 base

Base action for managing user pages.  Currently does nothing.

=cut

sub base : Chained('/base') PathPart('user') CaptureArgs(0) {}


=head2 resend_password / resend_password_GET / resend_password_POST

User forgot their password? Send them a reminder email with a password
reset link.

=cut

sub resend_password : Chained('base') PathPart('resend_password') Args(0) ActionClass('REST') {
    my ($self, $c) = @_;
    if (my $user = $c->user) {
        $self->go_here($c, '/user/edit', [$user->get('username')]);
        $c->detach();
    }
}
sub resend_password_GET {
    my ($self, $c) = @_;
    $c->stash->{template} = 'user/resend_password.tt2';
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
        $self->set_error_and_redirect(
            $c, q{Couldn't find an account with the given information.},
            ['/user/resend_password'],
        );
        $c->detach();
    }

    my $token     = $user->new_reset_token;
    my $token_val = $token->value;

    my $reset_uri = $c->uri_for_action('/user/list', [], {value => $token_val});
    my $email_content = <<"EMAIL";
To reset your password, please click on the following link:

  $reset_uri

If you have any trouble please contact us at help\@cellmigration.org.

Thanks!
The Judoon Team
EMAIL

    try {
        my $email = Email::Simple->create(
            header => [
                From    => '"Judoon" <help@cellmigration.org>',
                To      => $user->email_address,
                Subject => 'Judoon password reset',
            ],
            body => $email_content,
        );

        Email::Sender::Simple->send($email);
    }
    catch {
        my ($e) = $_;
        my $error = <<'EOE';
We are unable to send an email at the moment.  An admin has
been notified. Please try again later.
EOE
        $self->set_error_and_redirect($c, $error, ['/login/login']);
        $c->detach;
    };


    $self->set_notice($c, q{An email has been sent to the email address associated with the account.});
    $self->go_here($c, '/login/login');
}


=head2 list

Nothing useful here, redirect elsewhere

=cut

sub list : Chained('base') PathPart('') Args(0) {
    my ($self, $c) = @_;

    if (my $token = $c->req->params->{value}) {
        my $token = $c->model('User::Token')->find_by_value($token);
        if (not $token) {
            $self->set_error($c, 'No action found for token');
            $self->go_here($c, '/login/login');
        }
        else {
            $c->authenticate({id => $token->user->id}, 'password_reset');
            $self->go_here($c, '/user/password', {});
        }
    }
    elsif (my $user = $c->user) {
        $self->go_here($c, '/user/edit', [$user->get('username')]);
        $c->detach();
    }
    else {
        $self->go_here($c, '/login/login');
    }
}


=head2 id

Pull out the username from the url and search for that user.

=cut

sub id : Chained('base') PathPart('') CaptureArgs(1) {
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


=head2 edit

The user overview page that lists all the datasets and pages owned by
that user.

=cut

sub edit : Chained('id') PathPart('') Args(0) {
    my ($self, $c) = @_;
    $c->stash->{template} = 'user/edit.tt2';

    if ($c->stash->{user}{is_owner}) {
        my @datasets = $c->stash->{user}{object}->datasets_rs
            ->ordered_with_pages_and_pagecols->hri->all;

        my @url_keys = (
            [qw(edit_url        /private/dataset/object    )],
            [qw(column_list_url /private/datasetcolumn/list)],
            [qw(page_list_url   /private/page/list         )],
        );

        for my $dataset (@datasets) {

            $dataset->{ds_columns} = [
                $c->model('User::DatasetColumn')
                    ->for_dataset_id($dataset->{id})->hri->all
            ];

            for my $url_keys (@url_keys) {
                my ($url_stash_key, $url_action) = @$url_keys;
                $dataset->{$url_stash_key} = $c->uri_for_action(
                    $url_action,
                    [$c->stash->{user}{object}->username, $dataset->{id}],
                );
            }

            for my $page (@{$dataset->{pages}}) {

                # give page access to its parent dataset's scalar fields
                # this is only needed for the separate-lists overview template
                $page->{dataset} = {
                    map {$_ => $dataset->{$_}} grep {not ref $dataset->{$_}}
                        keys %$dataset
                };

                # not sure how to set this with dbic
                $page->{nbr_rows}    = $dataset->{nbr_rows};
                $page->{nbr_columns} = scalar @{$page->{page_columns}};

                $page->{edit_url} = $c->uri_for_action(
                    '/private/page/object',
                    [$c->stash->{user}{object}->username, $dataset->{id}, $page->{id}],
                );
            }
        }

        $c->stash->{dataset}{list} = \@datasets;
    }
    else {
        my @datasets = $c->stash->{user}{object}->datasets_rs->public
            ->ordered_with_pages_and_pagecols->hri->all;

        my @pages;
        for my $ds (@datasets) {
            $ds->{dataset_url} = $c->uri_for_action(
                '/private/dataset/object',
                [$c->stash->{user}{object}->username, $ds->{id}],
            );

            for my $page (@{ $ds->{pages} }) {
                next unless $page->{permission} eq 'public';
                $page->{page_url} = $c->uri_for_action(
                    '/private/page/object',
                    [$c->stash->{user}{object}->username, $ds->{id}, $page->{id}]
                );

                push @pages, $page;
            }

        }

        $c->stash->{dataset}{list} = \@datasets;
        $c->stash->{page}{list}    = \@pages;
    }

}


__PACKAGE__->meta->make_immutable;

1;
__END__
