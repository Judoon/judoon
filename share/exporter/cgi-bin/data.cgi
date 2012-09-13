#!/usr/bin/env perl

use strict;
use warnings;

use CGI ();
use Tie::File;

main: {
    my $cgi = CGI->new();
    my $params = $cgi->params();

    tie my @data, 'Tie::File', 'database.tab'
        or die "Cannot open database.csv: $!";

    my $filtered = my $total = @data;

    my @real_data;
    # filter data by search param
    if (my $search = $params->{sSearch}) {
        @real_data = grep {$data[$_] =~ m/$search/i} (1..$#data);
        $filtered = @real_data;
    }
    else {
        @real_data = @data[1..$#data];
    }

    # order data
    # iSortingCols: # of columns to sort by
    # sSortDir_#: asc/ desc
    # iSortCol_#: sort column number
    my $nbr_sort_cols = +($params->{iSortingCols} // 1);
    my $max_cols = split /\t/, $data[0];
    $nbr_sort_cols = $nbr_sort_cols > $max_cols ? $max_cols : $nbr_sort_cols;
    my @sorts = map {[$params->{"iSortCol_${_}"}, $params->{"sSortDir_${_}"}]}
        (0..$nbr_sort_cols-1);
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
