package Judoon::Web::Controller::Page;

=pod

=encoding utf8

=head1 NAME

Judoon::Web::Controller::Page - display public pages

=cut

use Moose;
use namespace::autoclean;

BEGIN { extends 'Judoon::Web::Controller'; }

with qw(
    Judoon::Web::Controller::Role::PublicDirectory
);


__PACKAGE__->config(
    action => {
        base => { Chained => '/base', PathPart => 'page', },
    },

    resultset_class => 'User::Page',
    stash_key       => 'page',
    template_dir    => 'public_page',
);


__PACKAGE__->meta->make_immutable;
1;
__END__
