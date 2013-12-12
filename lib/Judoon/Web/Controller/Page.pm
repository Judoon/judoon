package Judoon::Web::Controller::Page;

=pod

=encoding utf8

=head1 NAME

Judoon::Web::Controller::Page - display public pages

=cut

use Moose;
use namespace::autoclean;

BEGIN { extends 'Judoon::Web::Controller'; }

with qw(
    Judoon::Web::Controller::Role::PublicDirectory
    Judoon::Role::JsonEncoder
);


__PACKAGE__->config(
    action => {
        base => { Chained => '/base', PathPart => 'page', },
    },

    resultset_class => 'User::Page',
    stash_key       => 'page',
    template_dir    => 'public_page',
);



=head1 METHODS

=head2 populate_stash

Fill in the stash with the necessary data.

=cut

sub populate_stash {
    my ($self, $c, $page) = @_;

    $c->stash->{dataset}{id} = $page->dataset_id;
    my @page_columns = $page->page_columns_ordered->all;
    $c->stash->{column_json} = $self->encode_json([
        map {{
            title       => $_->title,
            template    => $_->template->to_jstmpl,
            sort_fields => join("|", $_->template->get_display_variables),
        }} @page_columns
    ]);

    return;
}


__PACKAGE__->meta->make_immutable;
1;
__END__
