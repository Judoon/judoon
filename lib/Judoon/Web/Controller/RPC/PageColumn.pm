package Judoon::Web::Controller::RPC::PageColumn;

use Moose;
use namespace::autoclean;

BEGIN { extends 'Judoon::Web::Controller::RPC'; }
with qw(Judoon::Web::Controller::Role::ExtractParams);


use JSON qw(encode_json);
use Judoon::SiteLinker;
use Judoon::Tmpl::Translator;
use List::AllUtils ();

has sitelinker => (is => 'ro', isa => 'Judoon::SiteLinker', lazy_build => 1);
sub _build_sitelinker { return Judoon::SiteLinker->new; }

__PACKAGE__->config(
    action => {
        base => { Chained => '/rpc/page/id', PathPart => 'column', },
    },
    rpc => {
        template_dir => 'page_column',
        stash_key    => 'page_column',
    },
);

has translator => (is => 'ro', isa => 'Judoon::Tmpl::Translator', lazy_build => 1,);
sub _build_translator { return Judoon::Tmpl::Translator->new; }


override add_object => sub {
    my ($self, $c, $params) = @_;
    my %valid = $self->extract_params('page_column', $params);
    $valid{template} = q{};
    return $c->stash->{page}{object}->create_related('page_columns', \%valid);
};

override get_object => sub {
    my ($self, $c) = @_;
    return $c->stash->{page}{object}->page_columns_rs
        ->find({id => $c->stash->{page_column}{id}});
};

after object_GET => sub {
    my ($self, $c) = @_;

    my @ds_columns = $c->stash->{dataset}{object}->ds_columns;
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
    my $rows = $c->stash->{dataset}{object}->data;
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

    my $page_column = $c->stash->{page_column}{object};
    if (my $template = $page_column->template) {
        $page_column->{webwidgets} = $page_column->template_to_webwidgets();
    }
};

override edit_object => sub {
    my ($self, $c, $params) = @_;
    return $c->stash->{page_column}{object}->update($params);
};

override munge_edit_params => sub {
    my ($self, $c) = @_;

    my $params        = $c->req->params;
    my $template_html = $params->{'page_column.template'};
    my $template      = $self->translator->translate(
        from => 'WebWidgets', to => 'Native', template => $template_html,
    );
    $params->{'page_column.template'} = $template;

    my %valid = $self->extract_params('page_column', $params);
    return \%valid;;
};


override delete_object => sub {
    my ($self, $c) = @_;
    $c->stash->{page_column}{object}->delete;
};

after object_DELETE => sub {
    my ($self, $c) = @_;
    my $captures = $c->req->captures;
    pop @$captures;
    $self->go_here($c, '/rpc/page/object', $captures);
};

__PACKAGE__->meta->make_immutable;

1;
__END__
