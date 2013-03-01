package Judoon::Web::Controller::Role::TabularData;

=pod

=encoding utf8

=head1 NAME

Judoon::Web::Controller::Role::TabularData - hand the user tabular data

=cut

use Moose::Role;
use namespace::autoclean;

=head2 table_view( @args? )

see L</DESCRIPTION>.

=cut

sub table_view {
    my ($self, $c, $view, $name, $headers, $rows) = @_;

    return unless ($view =~ m/^(?:tab|csv|xls|xlsx)$/);

    $c->stash->{tabular_data} = {
        view    => $view,
        name    => $name,
        headers => $headers,,
        rows    => $rows,
    };

    $c->forward('Judoon::Web::View::TabularData');

    return;
}


1;
__END__
