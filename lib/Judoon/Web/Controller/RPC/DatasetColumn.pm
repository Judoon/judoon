package Judoon::Web::Controller::RPC::DatasetColumn;

=pod

=encoding utf8

=head1 NAME

Judoon::Web::Controller::RPC::DatasetColumn - dataset column actions

=head1 DESCRIPTION

The RESTful controller for managing actions on one or more dataset
columns.  Chains off of L</Judoon::Web::Controller::RPC::Dataset>.

=cut

use Moose;
use namespace::autoclean;

BEGIN { extends 'Judoon::Web::Controller::RPC'; }
with qw(Judoon::Web::Controller::Role::ExtractParams);

use Data::Printer;

__PACKAGE__->config(
    action => {
        base => { Chained => '/rpc/dataset/chainpoint', PathPart => 'column', },
    },
    rpc => {
        template_dir => 'ds_column',
        stash_key    => 'ds_column',
        api_path     => 'datasetcolumn',
    },
);

=head2 sitelinker / _build_sitelinker

C<sitelinker> is a L</Judoon::SiteLinker> object.  This classes stores
what we know about linking accessions to websites.

=cut

has sitelinker => (is => 'ro', isa => 'Judoon::SiteLinker', lazy_build => 1);
sub _build_sitelinker { return Judoon::SiteLinker->new; }


=head2 list_GET (after)

Do some postprocessing on the dataset data to get sample data and set
up some convenience variables.

=cut

after list_GET => sub {
    my ($self, $c) = @_;

    my $columns = $c->stash->{ds_column}{list};
    use JSON::XS;
    my $rows    = decode_json($c->stash->{dataset}{object}{data});
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


=head2 object_GET (after)

Add accession types to stash.

=cut

after object_GET => sub {
    my ($self, $c) = @_;
    $c->stash->{accession_types} = $self->sitelinker->accession_groups;
};


=head2 object_PUT (after)

Redirect to dataset columns

=cut

after object_PUT => sub {
    my ($self, $c) = @_;
    my $captures = $c->req->captures;
    pop @$captures;
    $self->go_relative($c, 'list', $captures);
};

__PACKAGE__->meta->make_immutable;

1;
__END__

