#!/usr/bin/env perl

use strict;
use warnings;

BEGIN {
    use FindBin qw($Bin);
    push @INC, "$Bin/../cgi-lib";
}

use CGI ();
use Fcntl 'O_RDONLY';
use JSON qw(encode_json);
use Tie::File;


main: {
    my $cgi = CGI->new();
    my $params = $cgi->Vars();

    tie my @data, 'Tie::File', 'database.tab', mode => O_RDONLY
        or die "Cannot open database.tab: $!";

    my $filtered = my $total = (@data - 1);


    my @column_names = split /\t/, $data[0];
    my @real_data;
    # filter data by search param
    if (my $search = $params->{sSearch}) {
        @real_data = grep {m/$search/i} @data[1..$#data];
        $filtered = @real_data;
    }
    else {
        @real_data = @data[1..$#data];
    }
    @real_data = map {[split /\t/, $_]} @real_data;


    open my $types_fh, '<', 'datatypes.tab'
        or die "Cannot open datatypes.tab: $!";
    my @data_type = split /\t/, do { local $/ = undef; <$types_fh>; };
    close $types_fh;

    # order data
    # iSortingCols: # of columns to sort by
    # sSortDir_#: asc/ desc
    # iSortCol_#: sort column number
    my $nbr_sort_cols = +(defined($params->{iSortingCols}) ? $params->{iSortingCols} : 1);
    my $max_cols      = @column_names;
    $nbr_sort_cols    = $nbr_sort_cols > $max_cols ? $max_cols : $nbr_sort_cols;
    my @sorts = grep {defined($_->[0]) && defined($_->[1])}
        map {[$params->{"iSortCol_${_}"}, $params->{"sSortDir_${_}"}]}
            (0..$nbr_sort_cols-1);
    if (@sorts) {
        my $sort_func = sub {
            my ($left, $right) = @_;

            my $retval;
            for my $sort (@sorts) {
                my $idx = $sort->[0];
                $retval = $data_type[$idx] eq 'text'    ? ($left->[$idx]  cmp $right->[$idx])
                        : $data_type[$idx] eq 'numeric' ? ($left->[$idx]  <=> $right->[$idx])
                        :                                 die 'Unknown data type: ' . $data_type[$idx];
                $retval *= -1 if ($sort->[1] eq 'desc');
                last if ($retval);
            }
            return $retval;
        };
        @real_data = sort {$sort_func->($a, $b)} @real_data;
    }

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
    my @tmpl_data = map {
        my $row = $_;
        my $count = @{$row} - 1;
        +{map {$column_names[$_] => $row->[$_]} (0..$count)}
    } @real_data;


    print $cgi->header({
        -type => 'application/json',
    });
    print encode_json({
        tmplData             => \@tmpl_data,
        iTotalRecords        => $total,
        iTotalDisplayRecords => $filtered,
    });
}
