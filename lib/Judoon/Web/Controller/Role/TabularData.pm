package Judoon::Web::Controller::Role::TabularData;

=pod

=encoding utf8

=head1 NAME

Judoon::Web::Controller::Role::TabularData - hand the user tabular data

=head1 SYNOPSIS

 package Judoon::Web::Controller::Dataset
 with 'Judoon::Web::Controller::Role::TabularData';

 sub view {
    my ($self, $c) = @_;

    if ( my $view = $c->req->param('view') ) {
        $self->table_view(
            $c, $view, $dataset->name,
            $dataset->headers,
            $dataset->data,
        );
    }
 }

=head1 DESCRIPTION

C<Judoon::Web::Controller::Role::TabularData> sets up the stash keys
needed by L<Judoon::Web::View::TabularData>, then forwards to that
view.

=cut

use Moose::Role;
use namespace::autoclean;

use Judoon::Table;


=head1 METHODS

=head2 table_view( $c, $view, $name, \@headers, \@rows )

C<table_view()> makes sure that the requested view is one of our
supported formats, then sticks the passed arguments into the correct
stash keys.  It then forwards to L<Judoon::Web::View::TabularData>.

=cut

sub table_view {
    my ($self, $c, $view, $data_source) = @_;

    return unless ($view =~ m/^(?:tab|csv|xls|xlsx)$/);
    $c->stash->{tabular_data} = Judoon::Table->new({
        data_source  => $data_source,
        headers_type => 'long',
        format       => $view,
    });
    $c->forward('Judoon::Web::View::TabularData');

    return;
}


1;
__END__
