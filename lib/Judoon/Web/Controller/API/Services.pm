package Judoon::Web::Controller::API::Services;

use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller::REST'; }

__PACKAGE__->config(
    default => 'application/json',
    'map' => {
        'application/json' => 'JSON',
        'text/html' => 'YAML::HTML',
    },
);


sub base : Chained('/api/base') PathPart('') CaptureArgs(0) {}


sub template : Chained('base') PathPart('template') Args(0) ActionClass('REST') {}
sub template_POST {
    my ($self, $c) = @_;

    my $params = $c->req->data;
    if ($params->{widgets}) {
        my $tmpl = Judoon::Tmpl->new_from_data($params->{widgets});
        $self->status_ok($c, entity => { template => $tmpl->to_jstmpl });
    }
    elsif ($params->{template}) {
        my $tmpl = Judoon::Tmpl->new_from_jstmpl($params->{template});
        $self->status_ok($c, entity => { template => $tmpl->to_data });

    }
    else {
        $self->status_no_content($c);
    }
}


sub sitelinker : Chained('base') PathPart('sitelinker') CaptureArgs(0) {}
sub sl_index : Chained('sitelinker') PathPart('') Args(0) {
    my ($self, $c) = @_;
    # should probably be 204 with link="rel" to sites/accessions
    $self->status_no_content($c);
}
sub sl_accession_base : Chained('sitelinker') PathPart('accession') CaptureArgs(0) {}
sub sl_accession_list : Chained('sl_accession_base') PathPart('') Args(0) {
    my ($self, $c) = @_;
    $self->status_ok(
        $c, entity => $c->model('SiteLinker')->mapping->{accessions}
    );
}
sub sl_accession_id :Chained('sl_accession_base') PathPart('') Args(1) {
    my ($self, $c, $acc_id) = @_;

    $acc_id //= '';
    if (not exists $c->model('SiteLinker')->mapping->{accession}{$acc_id}) {
        $self->status_not_found($c, message => "No such accession: '$acc_id'");
        $c->detach();
    }

    my $accession = $c->model('SiteLinker')->mapping->{accession}{$acc_id};
    $self->status_ok($c, entity => { accession => $accession });
}

sub sl_site_base : Chained('sitelinker') PathPart('site') CaptureArgs(0) {}
sub sl_site_list : Chained('sl_site_base') PathPart('') Args(0) {
    my ($self, $c) = @_;
    $self->status_ok($c, entity => {
        sites => $c->model('SiteLinker')->mapping->{site}
    });
}




__PACKAGE__->meta->make_immutable;
1;
__END__
