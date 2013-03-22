package Judoon::Web::Controller::API::DatasetData;

=pod

=for stopwords ActionClass Datatables

=encoding utf8

=head1 NAME

Judoon::Web::Controller::API::DatasetData - Data API Controller

=cut

use Moose;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller::REST'; }

use List::AllUtils qw();
use SQL::Abstract;


=head1 ACTIONS

=head2 base

Does nothing currently, but calls to the api pass through here.

=head2 index

Return a simple response.

=head2 id

Grabs the dataset id from the url, looks it up in the database, then
stuffs it into the stash.

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
    $c->stash->{ds_column}{list} = [$c->stash->{dataset}{object}->ds_columns_ordered->all];
}


=head2 object / object_GET

REST ActionClass action.  Calling GET on this action returns the data
for the dataset in the stash, filtered by the query parameters.  The
query parameters are those set by the jQuery Datatables plugin.

=cut

sub object : Chained('id') PathPart('') Args(0) ActionClass('REST') {}

sub object_GET {
    my ($self, $c) = @_;

    my $dataset      = $c->stash->{dataset}{object};
    my $tbl_name     = $dataset->schema_name . '.' . $dataset->tablename;
    my $dbic_storage = $dataset->result_source->storage;
    my $params       = $c->req->params();
    my @ds_cols      = $dataset->ds_columns_ordered->with_lookups->hri->all;
    my @fields       = map {$_->{shortname}} @ds_cols;
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
    my @order_by;
    my $nbr_sort_cols = +($params->{iSortingCols} // 1);
    my $max_cols      = @fields;
    $nbr_sort_cols    = $nbr_sort_cols > $max_cols ? $max_cols : $nbr_sort_cols;
    for my $i (0..$nbr_sort_cols-1) {
        my $colnum    = $params->{"iSortCol_$i"} // 0;
        die "iSortCol_${i} must be a number between 0 and " . scalar(@fields)
            if ($colnum !~ m/^\d+$/ || $colnum < 0 || $colnum > @fields);

        my $dir_param = $params->{"sSortDir_$i"};
        my $direction = defined($dir_param) && $dir_param eq 'desc' ? 'desc'
                      :                                               'asc';

        my $field     = $fields[$colnum];
        my $data_type = $ds_cols[$colnum]->{data_type_rel}{data_type};
        my $sort_by   = $data_type eq 'text' ? $field
                      :                        \"CAST($field AS $data_type)";
        push @order_by, {"-$direction" => $sort_by};
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
