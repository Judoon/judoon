package Judoon::Web::Controller::API::Dataset;
use Moose;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller::REST'; }

use List::AllUtils qw();

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

    my @columns = @{$c->stash->{ds_column}{list}};
    my @real_data = @{$c->stash->{dataset}{object}->data};
    shift @real_data;
    my $total = @real_data;
    my $filtered = $total;

    my $params = $c->req->params();
    if (my $search = $params->{sSearch}) {
        $c->log->debug("Searching for $search...");
        @real_data = grep {List::AllUtils::any(sub {m/$search/i}, @$_)} @real_data;
        $filtered = @real_data;
    }


    my ($start, $end) = (0, $#real_data);
    my $len = $params->{iDisplayLength};
    if ($len && $len < $#real_data && $len > 0) {
        my $start_p = $params->{iDisplayStart};
        if ($start_p > $start && $start_p < $end) {
            $start = $start_p;
        }
        if ($start + $len < $#real_data) {
            $end = $start + $len - 1;
        }
    }
    @real_data = @real_data[$start..$end];


    my @tmpl_data;
    for my $data (@real_data) {
        my %yep;
        for my $i (0..$#columns) {
            $yep{$columns[$i]->shortname()} = $data->[$i];
        }
        push @tmpl_data, \%yep;
    }

    $self->status_ok($c,
        entity => {
            aaData               => \@real_data,
            tmplData             => \@tmpl_data,
            iTotalRecords        => $total,
            iTotalDisplayRecords => $filtered,
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
