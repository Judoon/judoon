package Judoon::Web::Controller::API::DatasetData;

=pod

=for stopwords Datatables

=encoding utf8

=head1 NAME

Judoon::Web::Controller::API::DatasetData - Data API Controller

=cut

use Moose;
use namespace::autoclean;

BEGIN { extends 'Judoon::Web::Controller'; }

use List::AllUtils qw();
use SQL::Abstract;

__PACKAGE__->config(
    'stash_key' => 'rest',
    'default'   => 'application/json',
    'map'       => {
        'application/json' => 'JSON',
    },
);


=head1 ACTIONS

=head2 begin / end

Deserialize / serialize the request / response.

=head2 data

Calling GET on this action returns the data for the dataset in the
stash, filtered by the query parameters.  The query parameters are
those set by the jQuery Datatables plugin.

=cut

sub begin : ActionClass('Deserialize') { }
sub end   : ActionClass('Serialize')   { }
sub data  : Chained('/api/wm/ds_data') PathPart('') Args(0) {
    my ($self, $c) = @_;

    my $dataset      = $c->stash->{dataset_object};
    my $tbl_name     = $dataset->schema_name . '.' . $dataset->tablename;
    my $dbic_storage = $dataset->result_source->storage;
    my $params       = $c->req->params();
    my @ds_cols      = $dataset->ds_columns_ordered->hri->all;
    my @fields       = map {$_->{shortname}} @ds_cols;
    my %ds_col_map   = map {$_->{shortname} => $_} @ds_cols;
    my $total        = $dataset->nbr_rows;

    # filter data
    #   sSearch: the search string
    my %where;
    if (my $search = $params->{sSearch} // '') {
        %where = ('-or' => {map {$_ => {-ilike => '%'.$search.'%'}} @fields});
    }

    # order data
    #   iSortingCols: # of columns to sort by
    #   sSortDir_#: asc/ desc
    #   iSortCol_#: sort column number
    my @sColumns = map {[split /\|/, $_]}
        split /,/, ($params->{sColumns} // '');
    my @order_by;
    my $nbr_sort_cols = +($params->{iSortingCols} // 1);
    for my $i (0..$nbr_sort_cols-1) {
        my $colnum    = $params->{"iSortCol_$i"} // 0;
        my $dir_param = $params->{"sSortDir_$i"};
        my $direction = defined($dir_param) && $dir_param eq 'desc' ? 'desc'
                      :                                               'asc';

        my $sort_fields = $sColumns[$colnum];
        for my $field (@$sort_fields) {
            my $data_type = $ds_col_map{$field}->{data_type};
            my $type_obj  = $c->model('TypeRegistry')->simple_lookup($data_type);
            my $pg_type   = $type_obj->pg_type;
            my $sort_by   = $pg_type eq 'text' ? $field
                          :                      \"CAST($field AS $pg_type)";
            push @order_by, {"-$direction" => $sort_by};
        }
    }

    # build and execute query
    my $sqla = SQL::Abstract->new;
    my ($stmt, @bind) = $sqla->select($tbl_name, \@fields, \%where, \@order_by);
    my $results = $dbic_storage->dbh_do(
        sub {
            my ($storage, $dbh) = @_;
            my $sth = $dbh->prepare($stmt);
            $sth->execute(@bind);
            return $sth->fetchall_arrayref({});
        },
    );
    my $filtered = %where ? @$results : $total;


    # paginate data
    #   iDisplayLength: number to show
    #   iDisplayStart: offset to start at
    my $limit  = $params->{iDisplayLength} // 50;
    my $offset = $params->{iDisplayStart}  // 0;
    die "iDisplayLength must be a number" unless ($limit =~ m/^\d+$/);
    die "iDisplayStart must be a number" unless ($offset =~ m/^\d+$/);

    my @tmpl_data = grep {defined} @{$results}[$offset..$offset+$limit];

    # return results
    $c->res->status(200);
    $c->stash->{rest} = {
        tmplData             => \@tmpl_data,
        iTotalRecords        => $total,
        iTotalDisplayRecords => $filtered,
        sEcho                => 0+($params->{sEcho} // 0),
    };
}



=head1 AUTHOR

Fitz Elliott

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
