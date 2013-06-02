package Judoon::Web::Controller::Private::PageColumn;

=pod

=encoding utf8

=head1 NAME

Judoon::Web::Controller::Private::PageColumn - page_column actions

=head1 DESCRIPTION

The RESTish controller for managing actions on one or more page
columns.  Currently chains off of ::Private::Page.

=cut

use Moose;
use namespace::autoclean;

BEGIN { extends 'Judoon::Web::ControllerBase::Private'; }
with qw(Judoon::Web::Controller::Role::ExtractParams);


use JSON qw(encode_json);
use Judoon::Tmpl;
use List::AllUtils ();


__PACKAGE__->config(
    action => {
        base => { Chained => '/private/page/chainpoint', PathPart => 'column', },
    },
    rpc => {
        template_dir => 'page_column',
        stash_key    => 'page_column',
        name         => 'page column',
        name_plural  => 'page columns',
    },

    # DBIC result class
    class                   =>  'User::PageColumn',
    # Columns required to create
    create_requires         =>  [qw/page_id template title/],
    # Additional non-required columns that create allows
    create_allows           =>  [qw//],
    # Columns that update allows
    update_allows           =>  [qw/page_id template title sort/],
    # Columns that list returns
    list_returns            =>  [qw/id page_id title template/],

    # Every possible prefetch parameter allowed
    list_prefetch_allows    =>  [
        [qw/datasets/], {  'datasets' => [qw/ds_columns pages/] },
    ],

    # Order of generated list
    list_ordered_by         => [qw/id/],
    # columns that can be searched on via list
    list_search_exposes     => [
        qw/id page_id title template/,
    ],
);


=head1 METHODS

=head2 generate_rs (around)

Restrict rs to C<PageColumns>s for the parent C<Page>.

=cut

around generate_rs => sub {
    my $orig = shift;
    my $self = shift;
    my $c    = shift;
    my $rs   = $self->$orig($c);
    return $rs->for_page($c->req->get_chained_object(-1)->[0])
        ->search_rs({}, {order_by => {-asc=>'sort'}});
};


=head2 validate_object (before)

Set page_id to chained C<Page>.

=cut

before validate_object => sub {
    my ($self, $c, $obj) = @_;
    my ($object, $params) = @$obj;
    $params->{page_id} //= $c->req->get_chained_object(-1)->[0]->id;
};


=head2 update_or_create (around)

On POST (create), if the template parameter is unset, default it to the
empty template ("[]").  If it's a PUT request, assume the user knows
what they're doing.

=cut

before update_or_create => sub {
    my ($self, $c) = @_;

    # default to empty template on create
    if ($c->req->method eq 'POST') {
        my $params = $c->req->get_object(-1)->[-1];
        $params->{template} ||= q{[]};
    }
};


=head2 private_base (before)

Restrict access to owners-only.

=cut

before private_base => sub {
    my ($self, $c) = @_;
    if (not $c->stash->{user}{is_owner}) {
        $self->set_error($c, 'You must be the owner to do this');
        $self->go_here($c, '/login/login', [],);
        $c->detach;
    }
};


=head2 list_GET (after)

Do some post-processing on the page columns data to get sample data and
js templates.

=cut

after list_GET => sub {
    my ($self, $c) = @_;

    my $dataset              = $c->req->get_chained_object(0)->[0];
    $c->stash->{sample_data} = encode_json( $dataset->sample_data );

    for my $column (@{$c->stash->{page_column}{list}}) {
        my $tmpl = Judoon::Tmpl->new_from_native($column->{template});
        $column->{js_template} = $tmpl->to_jstmpl;
    }
};


=head2 object_GET (after)

The C<PageColumn> edit pages needs lots of extra info for it to do
its job.  Add lots of metadata to stash.

=cut

after object_GET => sub {
    my ($self, $c) = @_;

    my $dataset                  = $c->req->get_chained_object(-2)->[0];
    my @ds_columns               = $dataset->ds_columns_ordered->all;
    $c->stash->{ds_column}{list} = \@ds_columns;
    $c->stash->{url_columns}     = [];

    my @acc_columns          = grep {$_->accession_type} @ds_columns;
    $c->stash->{acc_columns} = \@acc_columns;
    my $sitelinker           = $c->model('SiteLinker');
    for my $acc_column (@acc_columns) {
        my $sites = $sitelinker->mapping->{accession}{$acc_column->accession_type};
        my @links;
        for my $site (keys %$sites) {
            my $site_conf = $sitelinker->sites->{$site};
            push @links, {
                value   => $site_conf->{name},
                example => '',
                text    => $site_conf->{label},
            };
        }
        $acc_column->{linkset} = \@links;
    }

    $c->stash({
        column_acctype => encode_json(
            {map {$_->shortname => $_->accession_type} @acc_columns}
        ),
        ds_column_json => encode_json(
            [map {{name => $_->name, shortname => $_->shortname}} @ds_columns]
        ),

        link_site_json   => encode_json( $sitelinker->mapping->{site} ),
        sitelinker_sites => encode_json( $sitelinker->sites           ),
        sitelinker_accs  => encode_json( $sitelinker->accessions      ),
        url_prefixes     => encode_json( {}                           ),
        sample_data      => encode_json( $dataset->sample_data        ),
    });
};


=head2 object_PUT (before)

Convert template to native representation before updating.

=cut

before object_PUT => sub {
    my ($self, $c) = @_;

    my $params          = $c->req->get_object(0)->[1];
    my $template_html   = $params->{template} // '[]';
    $params->{template} = Judoon::Tmpl->new_from_native($template_html)
        ->to_native;
};


__PACKAGE__->meta->make_immutable;

1;
__END__
