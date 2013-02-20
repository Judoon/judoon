package Judoon::Web::Controller::Private::PageColumn;

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
        api_path     => 'pagecolumn',
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

Do some postprocessing on the page columns data to get js templates and add
"dataset columns used" list.

=cut

after list_GET => sub {
    my ($self, $c) = @_;

    my $dataset              = $c->req->get_chained_object(0)->[0];
    $c->stash->{sample_data} = encode_json( $dataset->sample_data );

    my %used;
    for my $column (@{$c->stash->{page_column}{list}}) {
        my $tmpl = Judoon::Tmpl->new_from_native($column->{template});
        $column->{js_template} = $tmpl->to_jstmpl;
        for my $var ($tmpl->get_variables) {
            push @{$used{$var}}, $column->{title};
        }
    }

    my @headers_used = map {{
        title => $_->name, used_in => join(', ', @{$used{$_->shortname} || []}),
    }} $dataset->ds_columns_ordered->all;
    $c->stash->{dataset}{headers_used} = \@headers_used;
};


after object_GET => sub {
    my ($self, $c) = @_;

    my $sitelinker = $c->model('SiteLinker');
    my $dataset = $c->req->get_chained_object(-2)->[0];
    my @ds_columns = $dataset->ds_columns_ordered->all;
    $c->stash->{ds_column}{list} = \@ds_columns;
    $c->stash->{url_columns} = [];
    my @acc_columns = grep {$_->accession_type} @ds_columns;
    $c->stash->{acc_columns}    = \@acc_columns;
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
    $c->stash->{column_acctype} = encode_json(
        {map {$_->shortname => $_->accession_type} @acc_columns}
    );

    $c->stash->{link_site_json} = encode_json(
        $sitelinker->mapping->{site}
    );
    $c->stash->{ds_column_json} = encode_json(
        [map {{name => $_->name, shortname => $_->shortname}} @ds_columns]
    );
    $c->stash->{sitelinker_sites} = encode_json( $sitelinker->sites );
    $c->stash->{sitelinker_accs}  = encode_json( $sitelinker->accessions );

    $c->stash->{url_prefixes} = encode_json({});

    $c->stash->{sample_data} = encode_json( $dataset->sample_data );
};

before object_PUT => sub {
    my ($self, $c) = @_;

    my $params        = $c->req->get_object(0)->[1];
    my $template_html = $params->{template} // '[]';
    $params->{template} = Judoon::Tmpl->new_from_native($template_html)->to_native;
};


after object_DELETE => sub {
    my ($self, $c) = @_;
    my $captures = $c->req->captures;
    pop @$captures;
    $self->go_here($c, '/private/pagecolumn/list', $captures);
};


__PACKAGE__->meta->make_immutable;

1;
__END__
