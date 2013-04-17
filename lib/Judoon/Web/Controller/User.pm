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


=head2 base

Base action for managing user pages.  Currently does nothing.

=cut

sub base : Chained('/base') PathPart('user') CaptureArgs(0) {}


=head2 list

Nothing useful here, redirect elsewhere

=cut

sub list : Chained('base') PathPart('') Args(0) {
    my ($self, $c) = @_;

    if (my $user = $c->user) {
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
        my @datasets = $c->stash->{user}{object}->datasets_rs->ordered->public->all;
        $c->stash->{dataset}{list} = \@datasets;
        $c->stash->{page}{list}    = [map {$_->pages_rs->ordered->public} @datasets];
    }

}


__PACKAGE__->meta->make_immutable;

1;
__END__
