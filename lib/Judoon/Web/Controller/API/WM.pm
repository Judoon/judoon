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
use HTTP::Response;

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
}


=head2 user_base / users / user_id / user

Information about Judoon users.

=cut

sub user_base : Chained('wm_base') PathPart('users') CaptureArgs(0) {
    my ($self, $c) = @_;
    $c->stash->{user_rs} = $c->model('User::User');
}
sub users : Chained('user_base') PathPart('') Args(0) ActionClass('FromPSGI') {
    my ($self, $c) = @_;
    return $self->wm(
        $c, 'Judoon::API::Resource::Users', {
            set      => $c->model('User::User'),
            writable => 0,
        }
    );
}
sub user_id : Chained('user_base') PathPart('') CaptureArgs(1) {
    my ($self, $c, $id) = @_;
    $c->stash->{user_id}     = $id;
    $c->stash->{user_object} = $c->stash->{user_rs}->find({username => $id});
}
sub user : Chained('user_id') PathPart('') Args(0) ActionClass('FromPSGI') {
    my ($self, $c) = @_;
    return $self->wm(
        $c, 'Judoon::API::Resource::User', {
            item     => $c->stash->{user_object},
            writable => 0,
        }
    );
}


=head2 dataset_base / datasets / dataset_id / dataset

Authenticated users get full access to their datasets and read access
to public datasets.

=cut

sub dataset_base : Chained('wm_base') PathPart('datasets') CaptureArgs(0) {
    my ($self, $c) = @_;
    $c->stash->{dataset_rs} = $c->model('User::Dataset')->public();
}
sub datasets : Chained('dataset_base') PathPart('') Args(0) ActionClass('FromPSGI') {
    my ($self, $c) = @_;
    return $self->wm(
        $c, 'Judoon::API::Resource::Datasets', {
            set      => $c->stash->{dataset_rs},
            writable => 0,
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
            writable => 0,
        }
    );
}


=head2 dscol_base() / dscols() / dscol()

Chains off of the parent dataset's C<dataset_id> action.  Actions are
restricted to the parent dataset's columns.

=cut

sub dscol_base : Chained('dataset_id') PathPart('columns') CaptureArgs(0) {
    my ($self, $c) = @_;
    my $ds = $c->stash->{dataset_object};
    $c->stash->{dscol_rs} = $ds ? $ds->ds_columns_ordered : undef;
}
sub dscols : Chained('dscol_base') PathPart('') Args(0) ActionClass('FromPSGI') {
    my ($self, $c) = @_;
    return $self->wm(
        $c, 'Judoon::API::Resource::DatasetColumns', {
            set      => $c->stash->{dscol_rs},
            writable => 0,
        }
    );
}
sub dscol : Chained('dscol_base') PathPart('') Args(1) ActionClass('FromPSGI') {
    my ($self, $c, $id) = @_;
    my $item = $c->stash->{dscol_rs}
        ? $c->stash->{dscol_rs}->find($id) : undef;
    return $self->wm(
        $c, 'Judoon::API::Resource::DatasetColumn', {
            item     => $item,
            writable => 0,
        }
    );
}


=head2 ds_page()

Get the list of pages for the given dataset.

=cut

sub ds_page : Chained('dataset_id') PathPart('pages') Args(0) ActionClass('FromPSGI') {
    my ($self, $c) = @_;
    return $self->wm(
        $c, 'Judoon::API::Resource::Pages', {
            set      => $c->stash->{dataset_object}->pages_ordered,
            writable => 0,
        }
    );
}


=head2 page_base / pages / page_id / page

Authenticated users get full access to their pages and read access
to public pages.

=cut

sub page_base : Chained('wm_base') PathPart('pages') CaptureArgs(0) {
    my ($self, $c) = @_;
    $c->stash->{page_rs} = $c->model('User::Page')->public();
}
sub pages : Chained('page_base') PathPart('') Args(0) ActionClass('FromPSGI') {
    my ($self, $c) = @_;
    return $self->wm(
        $c, 'Judoon::API::Resource::Pages', {
            set      => $c->stash->{page_rs},
            writable => 0,
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
            writable => 0,
        }
    );
}


=head2 pagecol_base() / pagecols() / pagecol()

Chains off of the parent page's C<page_id> action.  Actions are
restricted to the parent page's columns.

=cut

sub pagecol_base : Chained('page_id') PathPart('columns') CaptureArgs(0) {
    my ($self, $c) = @_;
    my $page = $c->stash->{page_object};
    $c->stash->{pagecol_rs} = $page ? $page->page_columns_ordered : undef;
}
sub pagecols : Chained('pagecol_base') PathPart('') Args(0) ActionClass('FromPSGI') {
    my ($self, $c) = @_;
    return $self->wm(
        $c, 'Judoon::API::Resource::PageColumns', {
            set      => $c->stash->{pagecol_rs},
            writable => 0,
        }
    );
}
sub pagecol : Chained('pagecol_base') PathPart('') Args(1) ActionClass('FromPSGI') {
    my ($self, $c, $id) = @_;
    my $item = $c->stash->{pagecol_rs}
        ? $c->stash->{pagecol_rs}->find({id => $id}) : undef;
    return $self->wm(
        $c, 'Judoon::API::Resource::PageColumn', {
            item     => $item,
            writable => 0,
        }
    );
}



1;
__END__
