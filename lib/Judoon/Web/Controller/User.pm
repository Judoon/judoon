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


=head1 ACTIONS

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
        $self->go_here($c, '/jsapp/user_view', [$user->get('username')]);
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

sub edit : Chained('id') PathPart('obsolete') Args(0) {
    my ($self, $c) = @_;
    $c->stash->{template} = 'user/edit.tt2';

    if ($c->stash->{user}{is_owner}) {
        my @datasets = $c->stash->{user}{object}->datasets_rs
            ->ordered_with_pages_and_pagecols->hri->all;

        my @url_keys = (
            [qw(edit_url        /jsapp/dataset_view )],
            [qw(column_list_url /jsapp/dataset_view )],
            [qw(page_list_url   /private/page/list  )],
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

                $page->{jsapp_url} = $c->uri_for_action(
                    '/jsapp/page_view',
                    [$c->stash->{user}{object}->username, $page->{id}],
                );
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
