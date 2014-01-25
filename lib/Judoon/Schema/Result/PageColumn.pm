package Judoon::Schema::Result::PageColumn;

=pod

=for stopwords InflateColumn

=encoding utf8

=head1 NAME

Judoon::Schema::Result::PageColumn

=cut

use Judoon::Schema::Candy;
use Judoon::Tmpl;

use Moo;
use namespace::clean;


table 'page_columns';


primary_column id => {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    is_serializable   => 1,
    is_numeric        => 1,
};
column page_id => {
    data_type       => "integer",
    is_foreign_key  => 1,
    is_nullable     => 0,
    is_serializable => 1,
    is_numeric      => 1,
};
column title => {
    data_type       => "text",
    is_nullable     => 0,
    is_serializable => 1,
};
column template => {
    data_type       => "text",
    is_nullable     => 0,
    is_serializable => 0,
};
column sort => {
    data_type       => "integer",
    is_nullable     => 0,
    is_serializable => 1,
    is_numeric      => 1,
};


belongs_to page => "::Page",
    { id => "page_id" },
    { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" };


=head1 EXTRA COMPONENTS

=head2 Ordered

Order C<PageColumn> by C<sort> column, grouping by C<page_id>.

=cut

__PACKAGE__->load_components(qw(Ordered));
__PACKAGE__->position_column('sort');
__PACKAGE__->grouping_column('page_id');


=head2 InflateColumn

The C<template> field of C<PageColumn> will be inflated to a
L<Judoon::Tmpl> object when C<< $page_column->template() >> is
called. Use C<< ->get_column('template') >> to get the raw data.

=cut

__PACKAGE__->inflate_column('template', {
    inflate => sub { Judoon::Tmpl->new_from_native(shift) },
    deflate => sub { shift->to_native },
});


=head2 ::Role::Result::HasTimestamps

Add <created> and <modified> columns to C<PageColumn>.

=cut

with qw(Judoon::Schema::Role::Result::HasTimestamps);
__PACKAGE__->register_timestamps;



=head1 METHODS

=head2 get_cloneable_columns()

Get the columns of this C<PageColumn> that are suitable for cloning,
i.e. everything but foreign keys.

=cut

sub get_cloneable_columns {
    my ($self) = @_;
    my %me = $self->get_columns;
    delete $me{id};
    delete $me{page_id};
    return %me;
}


=head2 sort_fields

Get the list of C<DatasetColumn> shortnames that we should use for
sorting our templates.  This is the list of variables found in the
plain text representation of the template. e.g. if the template is a
link node, it will return any variable used in the label portion of
the link, and ignore anything in the url portion.

=cut

sub sort_fields { shift->template->get_display_variables }


=head2 TO_JSON

A JSON representation of our page column.

=cut

sub TO_JSON {
    my ($self) = @_;
    return {
        template    => $self->template->to_jstmpl,
        widgets     => $self->template->to_data,
        sort_fields => join('|', $self->sort_fields),
        %{ $self->next::method },
    };
}


1;

=head1 AUTHOR

Fitz ELLIOTT <felliott@fiskur.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by the Rector and Visitors of the
University of Virginia.

This is free software, licensed under:

 The Artistic License 2.0 (GPL Compatible)

=cut
