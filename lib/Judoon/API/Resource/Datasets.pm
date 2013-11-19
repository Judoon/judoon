package Judoon::API::Resource::Datasets;

use HTTP::Headers;
use IO::File;

use Moo;
use namespace::clean;

extends 'Judoon::API::Resource';
with 'Judoon::Role::JsonEncoder';
with 'Judoon::API::Resource::Role::Set';


has createable => (is => 'ro', default => 0,);

around allowed_methods => sub {
    my $orig = shift;
    my $self = shift;

    my $methods = $orig->($self, @_);
    if ($self->createable) {
        push @$methods, 'POST';
    }
    return $methods;
};

around content_types_accepted => sub {
    my $orig = shift;
    my $self = shift;

    my $accepts = $orig->($self, @_);
    if ($self->createable) {
        push @$accepts, {
            'multipart/form-data' => "from_form",
        };
    }
    return $accepts;
};

sub from_form {
    my ($self, @args) = @_;

    my $req    = $self->request;
    my $upload = $req->uploads->{'dataset.file'};
    my $owner  = $self->set->related_resultset('user')->first;
    my $new_ds = $owner->import_data_by_filename($upload->{tempname});
    $self->_set_obj($new_ds);
}


1;
__END__

=pod

=encoding utf8

=for stopwords createable

=head1 NAME

Judoon::API::Resource::Datasets - A set of Datasets

=head1 DESCRIPTION

See L</Web::Machine::Resource>.

=head1 Attributes

=head2 createable

Signals that this resource can create new datasets. Defaults to false.

=head1 Methods

=head2 from_form

Process a C<multipart/form-data> request, extracting the upload in the
C<dataset.file> key, then passing it to
L<Judoon::Schema::Result::User>'s C<import_data_by_filename> method.

=cut
