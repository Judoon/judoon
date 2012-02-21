package Judoon::Web::Controller::RPC::DatasetColumn;

use Moose;
use namespace::autoclean;

BEGIN { extends 'Judoon::Web::Controller::RPC'; }

use Data::Printer;

__PACKAGE__->config(
    action => {
        base => { Chained => '/rpc/dataset/id', PathPart => 'column', },
    },
    rpc => {
        template_dir => 'ds_column',
        stash_key    => 'ds_column',
    },
);


override get_list => sub {
    my ($self, $c) = @_;
    return $c->model('Users')
        ->get_columns_for_dataset($c->stash->{dataset}{id});
};

after private_list => sub {
    my ($self, $c) = @_;

    my $columns = $c->stash->{ds_column}{list};
    my $rows    = $c->stash->{dataset}{object}{rows};
    for my $idx (0..scalar(@$columns)-1) {
        my $sample_count = 3;
        $columns->[$idx]{samples} = [];
        for my $row (@$rows) {
            last if ($sample_count <= 0);
            if (defined($row->[$idx]) && $row->[$idx] =~ m/\S/) {
                push @{$columns->[$idx]{samples}}, $row->[$idx];
                $sample_count--;
            }
        }
    }

    # this should be in the view
    for my $column (@$columns) {
        my @meta;
        if ($column->{is_accession}) {
            push @meta, 'accession: ' . $column->{accession_type};
        }
        if ($column->{is_url}) {
            push @meta, 'url: ' . $column->{url_root};
        }
        $column->{metadata} = @meta ? join(', ', @meta) : 'plain text';
    }

    $c->stash->{ds_column}{list} = $columns;
};


override manage_list => sub {
    my ($self, $c) = @_;

    my $params = $c->req->params;
    my $del_ids = $params->{'columns.delete'};
    my @del_ids = !defined $del_ids       ? ()
                : ref $del_ids eq 'ARRAY' ? @$del_ids
                : ref $del_ids eq ''      ? ($del_ids)
                :     die 'Unrecgonized type for "columns.delete"';

    for my $id (@del_ids) {
        $c->log->warn("Deleting column $id");
        $c->model('Users')->delete_column_for_dataset(
            $id, $c->stash->{dataset}{id},
        );
    }

    if (@del_ids) {
        $c->stash->{message} = "Columns " . join(', ', @del_ids)
            . ' deleted.';
    }

};

override get_object => sub {
    my ($self, $c) = @_;
    return $c->model('Users')->get_column($c->stash->{ds_column}{id});
};

override edit_object => sub {
    my ($self, $c, $params) = @_;
    my %valid = map {s/^column\.//r => $params->{$_}} grep {m/^column\./} keys %$params;
    $c->log->debug('Valid params are: ' . p(%valid));
    return $c->model('Users')
        ->update_column_metadata($c->stash->{ds_column}{id}, \%valid);
};

after private_edit => sub {
    my ($self, $c) = @_;
    $c->stash->{accession_types} = $c->model('Users')->accession_types();
};

after private_edit_do => sub {
    my ($self, $c) = @_;
    $c->res->redirect($c->uri_for_action('/rpc/datasetcolumn/list', [@{$c->req->captures}[0,1]]));
};

__PACKAGE__->meta->make_immutable;

1;
__END__

