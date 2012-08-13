package Judoon::Web::Controller::Dataset;

=pod

=encoding utf8

=head1 NAME

Judoon::Web::Controller::Dataset - display public datasets

=cut

use Moose;
use namespace::autoclean;

BEGIN { extends 'Judoon::Web::Controller'; }

with qw(
    Judoon::Web::Controller::Role::PublicDirectory
);


__PACKAGE__->config(
    action => {
        base => { Chained => '/base', PathPart => 'dataset', },
    },

    resultset_class => 'User::Dataset',
    stash_key       => 'dataset',
    template_dir    => 'public_dataset',
);


__PACKAGE__->meta->make_immutable;
1;
__END__
