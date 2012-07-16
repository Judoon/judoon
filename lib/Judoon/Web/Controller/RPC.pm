package Judoon::Web::Controller::RPC;

use Moose;
use namespace::autoclean;

BEGIN { extends 'Judoon::Web::Controller'; }


has rpc => (
    is  => 'ro',
    isa => 'HashRef',
);

__PACKAGE__->config(
    rpc => {
        template_dir => undef,
        stash_key    => undef,
    },
);


sub base      : Chained('fixme') PathPart('fixme') CaptureArgs(0) { shift->private_base(        @_); }
sub list      : Chained('base')  PathPart('')      Args(0)        :ActionClass('REST') {}
sub id        : Chained('base')  PathPart(''  )    CaptureArgs(1) { shift->private_id(          @_); }
sub object    : Chained('id')    PathPart('')      Args(0)        :ActionClass('REST') {}


sub private_base :Private {}


sub list_GET :Private {
    my ($self, $c) = @_;
    my $key                 = $self->rpc->{stash_key};
    $c->stash->{$key}{list} = $self->get_list($c);
    $c->stash->{template}   = $self->rpc->{template_dir} . '/list.tt2';
}

sub list_PUT :Private {
    my ($self, $c) = @_;
    $self->manage_list($c);
    $self->go_relative($c, 'list');
}

sub list_POST :Private {
    my ($self, $c) = @_;
    my $params = $self->munge_add_params($c);
    my $object = $self->add_object($c, $params);
    $self->go_relative($c, 'object', [@{$c->req->captures}, $object->id]);
}

sub private_id :Private {
    my ($self, $c, $id) = @_;
    my $key                   = $self->rpc->{stash_key};
    $c->stash->{$key}{id}     = $self->validate_id($c, $id);
    $c->stash->{$key}{object} = $self->get_object($c);
}


sub object_GET :Private {
    my ($self, $c) = @_;
    $c->stash->{template}   = $self->rpc->{template_dir} . '/edit.tt2';
}

sub object_PUT :Private {
    my ($self, $c) = @_;
    my $params                = $self->munge_edit_params($c);
    my $key                   = $self->rpc->{stash_key};
    $c->stash->{$key}{object} = $self->edit_object($c, $params);
    $self->go_relative($c, 'object');
}

sub object_DELETE :Private {
    my ($self, $c) = @_;
    $self->delete_object($c);
    my @captures = @{$c->req->captures};
    pop @captures;
    $self->go_relative($c, 'list', \@captures);
}



sub get_list          :Private { return [];    }
sub manage_list       :Private { return; }
sub munge_add_params  :Private { return $_[1]->req->params; }
sub add_object        :Private { return undef; }
sub validate_id       :Private { return $_[2]; }
sub get_object        :Private { return undef; }
sub munge_edit_params :Private { return $_[1]->req->params; }
sub edit_object       :Private { return undef; }
sub delete_object     :Private { return;       }


__PACKAGE__->meta->make_immutable;

1;
__END__
