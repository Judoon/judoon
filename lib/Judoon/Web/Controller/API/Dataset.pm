package Judoon::Web::Controller::API::Dataset;
use Moose;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller::REST'; }

=head1 NAME

Judoon::Web::Controller::API::Dataset - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub base : Chained('/api/base') PathPart('dataset')  CaptureArgs(0) {}
sub index :Chained('base')  PathPart('')    Args(0) {
    my ($self, $c) = @_;
    $c->res->body('got here');
}
sub id : Chained('base') PathPart('') CaptureArgs(1) {
    my ($self, $c, $ds_id) = @_;

    $c->stash->{dataset}{id} = $ds_id;
    $c->stash->{dataset}{object} = $c->model('User::Dataset')->find({id => $ds_id});
    $c->stash->{ds_column}{list} = [$c->stash->{dataset}{object}->ds_columns];
}

sub object : Chained('id') PathPart('') Args(0) ActionClass('REST') {}

sub object_GET {
    my ($self, $c) = @_;

    my @real_data = @{$c->stash->{dataset}{object}->data};
    shift @real_data;

    my @columns = @{$c->stash->{ds_column}{list}};

    my @tmpl_data;
    for my $data (@real_data) {
        my %yep;
        for my $i (0..$#columns) {
            $yep{$columns[$i]->shortname()} = $data->[$i];
        }
        push @tmpl_data, \%yep;
    }

    use Data::Printer;
    my %d = (entity => {
            dataset  => $c->stash->{dataset}{object},
            aaData   => \@real_data,
            tmplData => \@tmpl_data,
        });
    $c->log->debug('Bup: ' . p(%d));

    $self->status_ok($c,
        entity => {
            #dataset  => $c->stash->{dataset}{object},
            aaData   => \@real_data,
            tmplData => \@tmpl_data,
        },
    );
}

=head1 AUTHOR

Fitz Elliott

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
