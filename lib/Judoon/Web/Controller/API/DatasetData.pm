package Judoon::Web::Controller::API::DatasetData;
use Moose;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller::REST'; }

use List::AllUtils qw();

=head1 NAME

Judoon::Web::Controller::API::DatasetData - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub base : Chained('/api/base') PathPart('datasetdata')  CaptureArgs(0) {}
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
    my $filtered = my $total = @real_data;

    # filter data by search param
    my $params = $c->req->params();
    if (my $search = $params->{sSearch}) {
        @real_data = grep {List::AllUtils::any(sub {m/$search/i}, @$_)} @real_data;
        $filtered = @real_data;
    }

    # order data
    # iSortingCols: # of columns to sort by
    # sSortDir_#: asc/ desc
    # iSortCol_#: sort column number
    my $nbr_sort_cols = +($params->{iSortingCols} // 1);
    my $max_cols = $c->stash->{dataset}{object}->nbr_columns;
    $nbr_sort_cols = $nbr_sort_cols > $max_cols ? $max_cols : $nbr_sort_cols;
    my @sorts;
    for my $i (0..$nbr_sort_cols-1) {
        push @sorts, [$params->{"iSortCol_$i"}, $params->{"sSortDir_$i"}];
    }
    my $sort_func = sub {
        my ($left, $right) = @_;

        my $retval;
        for my $sort (@sorts) {
            my $idx = $sort->[0];
            $retval = $sort->[1] eq 'asc' ? ($left->[$idx]  cmp $right->[$idx])
                    :                       ($right->[$idx] cmp $left->[$idx] );
            last if ($retval);
        }
        return $retval;
    };
    @real_data = sort {$sort_func->($a, $b)} @real_data;


    # paginate data
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

    # turn 2D data array into list of hashrefs
    my @column_names = map {$_->shortname} @{$c->stash->{ds_column}{list}};
    my @tmpl_data = map {{ List::AllUtils::zip @column_names, @$_ }} @real_data;

    $self->status_ok($c,
        entity => {
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
