package Judoon::Web::Controller::API::DatasetData;
use Moose;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller::REST'; }

use List::AllUtils qw();
use SQL::Abstract;

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
    $c->stash->{ds_column}{list} = [$c->stash->{dataset}{object}->ds_columns_ordered->all];
}

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
    if (my $search = $params->{sSearch}) {
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
        my ($colnum, $direction) = @{$params}{("iSortCol_$i", "sSortDir_$i")};

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
    my ($limit, $offset) = @{$params}{qw(iDisplayLength iDisplayStart)};
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
