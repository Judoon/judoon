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

use List::Util qw();


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



sub lookup : Chained('base') PathPart('lookup') CaptureArgs(0) {}
sub lookup_index : Chained('lookup') PathPart('') Args(0) {
    my ($self, $c) = @_;
    $self->status_ok(
        $c, entity => [
            map {$_->TO_JSON} $c->model('LookupRegistry')->all_lookups()
        ]
    );
}

sub look_type : Chained('lookup') PathPart('') CaptureArgs(1) {
    my ($self, $c, $type) = @_;

    $c->stash->{lookup}{type} = $type;
    $c->stash->{lookup}{list}
        = $type eq 'internal' ? [$c->model('LookupRegistry')->internals()]
        : $type eq 'external' ? [$c->model('LookupRegistry')->externals()]
        :                       undef;

    if (!$c->stash->{lookup}{list}) {
        $self->status_not_found(
            $c, message => "Unrecognized lookup type '$type'"
        );
        $c->detach();
    }
}

sub look_type_final : Chained('look_type') PathPart('') Args(0) {
    my ($self, $c) = @_;
    $self->status_ok($c, entity => [
        map {$_->TO_JSON} @{ $c->stash->{lookup}{list} }
    ]);
}

sub look_id : Chained('look_type') PathPart('') CaptureArgs(1) {
    my ($self, $c, $lookup_id) = @_;

    $c->stash->{lookup}{id}     = $lookup_id;
    $c->stash->{lookup}{object} = $c->model('LookupRegistry')
        ->find_by_type_and_id( $c->stash->{lookup}{type}, $lookup_id );

    if (!$c->stash->{lookup}{object}) {
        $self->status_not_found(
            $c, message => "Unrecognized lookup id '$lookup_id'"
        );
        $c->detach();
    }
}

sub look_id_final : Chained('look_id') PathPart('') Args(0) {
    my ($self, $c) = @_;
    $self->status_ok($c, entity => $c->stash->{lookup}{object}->TO_JSON);
}

sub look_input : Chained('look_id') PathPart('input') CaptureArgs(0) {
    my ($self, $c) = @_;
    $c->stash->{lookup}{input}{list}
        = $c->stash->{lookup}{object}->input_columns;
}
sub look_input_final : Chained('look_input') PathPart('') Args(0) {
    my ($self, $c) = @_;
    $self->status_ok($c, entity => $c->stash->{lookup}{input}{list});
}


sub look_input_id : Chained('look_input') PathPart('') CaptureArgs(1) {
    my ($self, $c, $id) = @_;

    $c->stash->{lookup}{input}{id} = $id;
    $c->stash->{lookup}{input}{object} = List::Util::first {$_->{id} eq $id}
        @{ $c->stash->{lookup}{input}{list} };

    if (!$c->stash->{lookup}{input}{object}) {
        $self->status_not_found(
            $c, message => "Unrecognized lookup input object '$id'"
        );
        $c->detach();
    }
}
sub look_input_id_final : Chained('look_input_id') PathPart('') Args(0) {
    my ($self, $c) = @_;
    $self->status_ok($c, entity => $c->stash->{lookup}{input}{object});
}

sub look_input_to_output : Chained('look_input_id') PathPart('output') CaptureArgs(0) {
    my ($self, $c) = @_;

    $c->stash->{lookup}{output}{list}
        = $c->stash->{lookup}{object}->output_columns_for(
            $c->stash->{lookup}{input}{object}
        );
}
sub look_input_to_output_final : Chained('look_input_to_output') PathPart('') Args(0) {
    my ($self, $c) = @_;
    $self->status_ok($c, entity => $c->stash->{lookup}{output}{list});
}

__PACKAGE__->meta->make_immutable;
1;
__END__
