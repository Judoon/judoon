package Judoon::Web::Controller::Private::PageColumn;

use Moose;
use namespace::autoclean;

BEGIN { extends 'Judoon::Web::ControllerBase::Private'; }
with qw(Judoon::Web::Controller::Role::ExtractParams);


use JSON qw(encode_json);
use Judoon::SiteLinker;
use Judoon::Tmpl::Translator;
use List::AllUtils ();

has sitelinker => (is => 'ro', isa => 'Judoon::SiteLinker', lazy => 1, builder => '_build_sitelinker',);
sub _build_sitelinker { return Judoon::SiteLinker->new; }

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

has translator => (is => 'ro', isa => 'Judoon::Tmpl::Translator', lazy => 1, builder => '_build_translator',);
sub _build_translator { return Judoon::Tmpl::Translator->new; }


before private_base => sub {
    my ($self, $c) = @_;
    if (not $c->stash->{user}{is_owner}) {
        $c->flash->{alert}{error} = 'You must be the owner to see this page';
        $self->go_here($c, '/login/login', []);
        $c->detach;
    }
};


after object_GET => sub {
    my ($self, $c) = @_;

    my $dataset = $c->req->get_chained_object(-2)->[0];
    my @ds_columns = $dataset->ds_columns;
    $c->stash->{ds_column}{list} = \@ds_columns;
    $c->stash->{url_columns} = [grep {$_->is_url} @ds_columns];
    my @acc_columns = grep {$_->is_accession} @ds_columns;
    $c->stash->{acc_columns}    = \@acc_columns;
    $c->stash->{column_acctype} = encode_json(
        {map {$_->shortname => $_->accession_type} @acc_columns}
    );

    $c->stash->{link_site_json} = encode_json(
        $self->sitelinker->mapping->{site}
    );
    $c->stash->{ds_column_json} = encode_json(
        [map {{name => $_->name, shortname => $_->shortname}} @ds_columns]
    );
    $c->stash->{sitelinker_sites} = encode_json( $self->sitelinker->sites );
    $c->stash->{sitelinker_accs}  = encode_json( $self->sitelinker->accessions );

    $c->stash->{url_prefixes} = encode_json({
        map {$_->shortname => $_->url_root} @{$c->stash->{url_columns}}
    });

    # copied & pasted from DataSetColumn
    # need to factor this out.
    my $rows = $dataset->data;
    my @sample_data;
    for my $idx (0..$#ds_columns) {
      ROW_SEARCH:
        for my $row (@$rows) {
            if (defined($row->[$idx]) && $row->[$idx] =~ m/\S/) {
                push @sample_data, $row->[$idx];
                last ROW_SEARCH;
            }
        }
    }
    my %sample_data;
    @sample_data{map {$_->shortname} @ds_columns} = @sample_data;
    $c->stash->{sample_data} = encode_json( \%sample_data );
};

before object_PUT => sub {
    my ($self, $c) = @_;

    my $params        = $c->req->get_object(0)->[1];
    my $template_html = $params->{template} // '[]';
    my $template      = $self->translator->translate(
        from => 'Native', to => 'Native', template => $template_html,
    );
    $params->{'template'} = $template;
};


after object_DELETE => sub {
    my ($self, $c) = @_;
    my $captures = $c->req->captures;
    pop @$captures;
    $self->go_here($c, '/private/page/object', $captures);
};

__PACKAGE__->meta->make_immutable;

1;
__END__
