package Judoon::Web::Controller::Private::DatasetColumn;

=pod

=encoding utf8

=head1 NAME

Judoon::Web::Controller::Private::DatasetColumn - dataset column actions

=head1 DESCRIPTION

The RESTful controller for managing actions on one or more dataset
columns.  Chains off of L</Judoon::Web::Controller::Private::Dataset>.

=cut

use Moose;
use namespace::autoclean;

BEGIN { extends 'Judoon::Web::ControllerBase::Private'; }
with qw(Judoon::Web::Controller::Role::ExtractParams);

use JSON::XS qw(decode_json);

__PACKAGE__->config(
    action => {
        base => { Chained => '/private/dataset/chainpoint', PathPart => 'column', },
    },
    rpc => {
        template_dir => 'ds_column',
        stash_key    => 'ds_column',
        api_path     => 'datasetcolumn',
    },
);


before private_base => sub {
    my ($self, $c) = @_;
    if (not $c->stash->{user}{is_owner}) {
        $c->flash->{alert}{error} = 'You must be the owner to see this page';
        $self->go_here($c, '/login/login', []);
        $c->detach;
    }
};


=head2 list_GET (after)

Do some postprocessing on the dataset data to get sample data and set
up some convenience variables.

=cut

after list_GET => sub {
    my ($self, $c) = @_;

    my $columns = $c->stash->{ds_column}{list};
    my $dataset = $c->req->get_chained_object(0)->[0];
    my $rows    = $dataset->data;
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
        if (exists $column->{accession_type}) {
            push @meta, 'accession: ' . $column->{accession_type};
        }
        $column->{metadata} = @meta ? join(', ', @meta) : 'plain text';
    }

    $c->stash->{ds_column}{list} = $columns;
};


=head2 object_GET (after)

Add accession types to stash.

=cut

after object_GET => sub {
    my ($self, $c) = @_;
    $c->stash->{accession_types} = $c->model('SiteLinker')->accession_groups;
};


__PACKAGE__->meta->make_immutable;

1;
__END__

