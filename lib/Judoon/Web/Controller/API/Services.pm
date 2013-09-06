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



__PACKAGE__->meta->make_immutable;
1;
__END__
