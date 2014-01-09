package Judoon::API::Resource::Datasets;

use HTTP::Headers::ActionPack::LinkHeader;
use HTTP::Throwable::Factory qw(http_throw);
use Safe::Isa;
use Try::Tiny;

use Moo;
use namespace::clean;

extends 'Judoon::API::Resource';
with 'Judoon::Role::JsonEncoder';
with 'Judoon::API::Resource::Role::Set';

has new_page   => (is => 'rw', writer => '_set_new_page');
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
    my ($self) = @_;

    my $upload = $self->request->uploads->{'dataset.file'};
    if (not $upload) {
        http_throw(UnprocessableEntity => {
            message => 'No spreadsheet provided!',
        });
    }

    my $owner  = $self->set->get_our_owner();

    my $new_ds;
    try {
        $new_ds = $owner->import_data_by_filename($upload->tempname);
    }
    catch {
        my $e = $_;
        $e->$_DOES('Judoon::Error::Spreadsheet')
            ? http_throw(UnprocessableEntity => {message => $e->message})
            : die $e;
    };
    $self->_set_new_page($new_ds->create_basic_page());
    $self->_set_obj($new_ds);
}

around 'finish_request' => sub {
    my ($orig, $self, $metadata) = @_;

    $self->$orig($metadata);

    if ($self->new_page) {
        my $page_url = '/api/pages/' . $self->new_page->id;
        my $link = HTTP::Headers::ActionPack::LinkHeader->new(
            $page_url => (
                rel   => "default_page",
                title => "default page",
            )
        );
        $self->response->header(Link => $link->as_string);
    }
};



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

=head2 new_page

Attribute to hold the new default page created.

=head1 Methods

=head2 from_form

Process a C<multipart/form-data> request, extracting the upload in the
C<dataset.file> key, then passing it to
L<Judoon::Schema::Result::User>'s C<import_data_by_filename> method.

=head2 finalize_request

If a new page was created, add a Link header to the response that
points to the page.

=cut
