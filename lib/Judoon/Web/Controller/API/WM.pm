package Judoon::Web::Controller::API::WM;

use Moose;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller'; }

use Judoon::API::Machine;
use Module::Load;


sub wm {
    my ($self, $c, $machine_class, $machine_args) = @_;
    load $machine_class;
    Judoon::API::Machine->new(
        resource      => $machine_class,
        resource_args => [ %{ $machine_args } ],
    )->to_app;
}


sub wm_base : Chained('/api/base') PathPart('') CaptureArgs(0) {
    my ($self, $c) = @_;
    $c->stash->{authd_user} = $c->user->get_object if ($c->user);
}



sub dataset_base : Chained('wm_base') PathPart('dataset') CaptureArgs(0) {
    my ($self, $c) = @_;

    my $set = $c->model('User::Dataset');
    if (not $c->stash->{authd_user}) {
        $set = $set->public();
    }
    elsif ($c->request->method eq 'GET') {
        $set = $set->search_or([
            $set->for_user($c->stash->{authd_user}),
            $set->public
        ]);
    }
    else {
        $set = $set->for_user($c->stash->{authd_user});
    }
    $c->stash->{dataset_rs} = $set;

    return;
}
sub datasets : Chained('dataset_base') PathPart('') Args(0) ActionClass('FromPSGI') {
    my ($self, $c) = @_;
    return $self->wm(
        $c, 'Judoon::API::Resource::Datasets', {
            set      => $c->stash->{dataset_rs},
            writable => !!$c->stash->{authd_user},
        }
    );
}
sub dataset_id : Chained('dataset_base') PathPart('') CaptureArgs(1) {
    my ($self, $c, $id) = @_;
    $c->stash->{dataset_id} = $id;
}
sub dataset : Chained('dataset_id') PathPart('') Args(0) ActionClass('FromPSGI') {
    my ($self, $c) = @_;
    my $item = $c->stash->{dataset_rs}->find($c->stash->{dataset_id});
    return $self->wm(
        $c, 'Judoon::API::Resource::Dataset', {
            item     => $item,
            writable => !!$c->stash->{authd_user},
        }
    );
}



sub dscol_base : Chained('dataset_id') PathPart('column') CaptureArgs(0) {
    my ($self, $c) = @_;
    $c->stash->{dscol_rs} = $c->stash->{dataset_rs}
        ->related_resultset('ds_columns');
}
sub dscols : Chained('dscol_base') PathPart('') Args(0) ActionClass('FromPSGI') {
    my ($self, $c) = @_;
    return $self->wm(
        $c, 'Judoon::API::Resource::DatasetColumn', {
            set      => $c->stash->{dscol_rs},
            writable => !!$c->stash->{authd_user},
        }
    );
}
sub dscol : Chained('dscol_base') PathPart('') Args(1) ActionClass('FromPSGI') {
    my ($self, $c, $id) = @_;
    my $item = $c->stash->{dscol_rs}->find($id);
    return $self->wm(
        $c, 'Judoon::API::Resource::DatasetColumn', {
            item     => $item,
            writable => !!$c->stash->{authd_user},
        }
    );
}


sub page_base : Chained('wm_base') PathPart('page') CaptureArgs(0) {
    my ($self, $c) = @_;

    my $set = $c->model('User::Page');
    if (not $c->stash->{authd_user}) {
        $set = $set->public();
    }
    elsif ($c->request->method eq 'GET') {
        $set = $set->for_user($c->stash->{authd_user})->union($set->public);
    }
    else {
        $set = $set->for_user($c->stash->{authd_user});
    }
    $c->stash->{page_rs} = $set;

    return;
}
sub pages : Chained('page_base') PathPart('') Args(0) ActionClass('FromPSGI') {
    my ($self, $c) = @_;
    return $self->wm(
        $c, 'Judoon::API::Resource::Pages', {
            set      => $c->stash->{page_rs},
            writable => !!$c->stash->{authd_user},
        }
    );
}
sub page_id : Chained('page_base') PathPart('') CaptureArgs(1) {
    my ($self, $c, $id) = @_;
    $c->stash->{page_id} = $id;
}
sub page : Chained('page_id') PathPart('') Args(0) ActionClass('FromPSGI') {
    my ($self, $c, $id) = @_;

    my $item = $c->stash->{page_rs}->find(
        {id => $c->stash->{page_id}}
    );
    return $self->wm(
        $c, 'Judoon::API::Resource::Page', {
            item     => $item,
            writable => !!$c->stash->{authd_user},
        }
    );
}


sub pagecol_base : Chained('page_id') PathPart('column') CaptureArgs(0) {
    my ($self, $c) = @_;
    $c->stash->{pagecol_rs} = $c->stash->{page_rs}
        ->related_resultset('page_columns');
    return;
}
sub pagecols : Chained('pagecol_base') PathPart('') Args(0) ActionClass('FromPSGI') {
    my ($self, $c) = @_;
    return $self->wm(
        $c, 'Judoon::API::Resource::PageColumns', {
            set      => $c->stash->{pagecol_rs},
            writable => !!$c->stash->{authd_user},
        }
    );
}
sub pagecol : Chained('pagecol_base') PathPart('') Args(1) ActionClass('FromPSGI') {
    my ($self, $c, $id) = @_;
    my $item = $c->stash->{pagecol_rs}->find({id => $id});
    return $self->wm(
        $c, 'Judoon::API::Resource::PageColumn', {
            item     => $item,
            writable => !!$c->stash->{authd_user},
        }
    );
}



1;
__END__
