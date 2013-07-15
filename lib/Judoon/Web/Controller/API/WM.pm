package Judoon::Web::Controller::API::WM;

=pod

=encoding utf8

=head1 NAME

Judoon::Web::Controller::WM - dispatcher to our Judoon::API::Machine::* modules

=head1 DESCRIPTION

This controller manages permissions and dispatch requests for our
L</Web::Machine>-based REST API.

=cut

use Moose;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller'; }

use Judoon::API::Machine;
use Module::Load;


=head1 Methods

=head2 wm( $c, $machine_class, $machine_args )

Construct a L</Web::Machine::Resource> app of class C<$machine_class>
with the given arguments (C<$machine_args>).

=cut

sub wm {
    my ($self, $c, $machine_class, $machine_args) = @_;
    load $machine_class;
    Judoon::API::Machine->new(
        resource      => $machine_class,
        resource_args => [ %{ $machine_args } ],
    )->to_app;
}


=head1 Actions

=head2 wm_base

The base action for all other actions.  Puts the authenticated user in
the stash.

=cut

sub wm_base : Chained('/api/base') PathPart('') CaptureArgs(0) {
    my ($self, $c) = @_;
    $c->stash->{authd_user} = $c->user->get_object if ($c->user);
}


=head2 dataset_base / datasets / dataset_id / dataset

Authenticated users get full access to their datasets and read access
to public datasets.

=cut

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

    $c->stash->{dataset_id}     = $id;
    $c->stash->{dataset_object} = $c->stash->{dataset_rs}->find({id => $id});
}
sub dataset : Chained('dataset_id') PathPart('') Args(0) ActionClass('FromPSGI') {
    my ($self, $c) = @_;
    return $self->wm(
        $c, 'Judoon::API::Resource::Dataset', {
            item     => $c->stash->{dataset_object},
            writable => !!$c->stash->{authd_user},
        }
    );
}


=head2 dscol_base() / dscols() / dscol()

Chains off of the parent dataset's C<dataset_id> action.  Actions are
restricted to the parent dataset's columns.

=cut

sub dscol_base : Chained('dataset_id') PathPart('column') CaptureArgs(0) {
    my ($self, $c) = @_;
    my $ds = $c->stash->{dataset_object};
    $c->stash->{dscol_rs} = $ds ? $ds->ds_columns_ordered : undef;
}
sub dscols : Chained('dscol_base') PathPart('') Args(0) ActionClass('FromPSGI') {
    my ($self, $c) = @_;
    return $self->wm(
        $c, 'Judoon::API::Resource::DatasetColumns', {
            set      => $c->stash->{dscol_rs},
            writable => !!$c->stash->{authd_user},
        }
    );
}
sub dscol : Chained('dscol_base') PathPart('') Args(1) ActionClass('FromPSGI') {
    my ($self, $c, $id) = @_;
    my $item = $c->stash->{dscol_rs}
        ? $c->stash->{dscol_rs}->find($id)
        : undef;
    return $self->wm(
        $c, 'Judoon::API::Resource::DatasetColumn', {
            item     => $item,
            writable => !!$c->stash->{authd_user},
        }
    );
}


=head2 page_base / pages / page_id / page

Authenticated users get full access to their pages and read access
to public pages.

=cut

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

    $c->stash->{page_id}     = $id;
    $c->stash->{page_object} = $c->stash->{page_rs}->find({id => $id});
}
sub page : Chained('page_id') PathPart('') Args(0) ActionClass('FromPSGI') {
    my ($self, $c, $id) = @_;
    return $self->wm(
        $c, 'Judoon::API::Resource::Page', {
            item     => $c->stash->{page_object},
            writable => !!$c->stash->{authd_user},
        }
    );
}


=head2 pagecol_base() / pagecols() / pagecol()

Chains off of the parent page's C<page_id> action.  Actions are
restricted to the parent page's columns.

=cut

sub pagecol_base : Chained('page_id') PathPart('column') CaptureArgs(0) {
    my ($self, $c) = @_;
    my $page = $c->stash->{page_object};
    $c->stash->{pagecol_rs} = $page ? $page->page_columns_ordered : undef;
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
    my $item = $c->stash->{pagecol_rs}
        ? $c->stash->{pagecol_rs}->find({id => $id})
        : undef;
    return $self->wm(
        $c, 'Judoon::API::Resource::PageColumn', {
            item     => $item,
            writable => !!$c->stash->{authd_user},
        }
    );
}



1;
__END__
