package Judoon::Schema::Result::PageColumn;

=pod

=for stopwords InflateColumn

=encoding utf8

=head1 NAME

Judoon::Schema::Result::PageColumn

=cut

use Moo;
extends 'Judoon::Schema::Result';


use Judoon::Tmpl;


=head1 TABLE: C<page_columns>

=cut

__PACKAGE__->table("page_columns");


=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 page_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 title

  data_type: 'text'
  is_nullable: 0

=head2 template

  data_type: 'text'
  is_nullable: 0

=head2 sort

  data_type: 'integer'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
    id => {
        data_type         => "integer",
        is_auto_increment => 1,
        is_nullable       => 0,
    },
    page_id => {
        data_type      => "integer",
        is_foreign_key => 1,
        is_nullable    => 0,
    },
    title => {
        data_type       => "text",
        is_nullable     => 0,
        is_serializable => 1,
    },
    template => {
        data_type   => "text",
        is_nullable => 0,
    },
    sort => {
        data_type   => "integer",
        is_nullable => 0,
    },
);


=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");


=head1 RELATIONS

=head2 page

Type: belongs_to

Related object: L<Judoon::Schema::Result::Page>

=cut

__PACKAGE__->belongs_to(
    page => "::Page",
    { id => "page_id" },
    { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


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


sub TO_JSON {
    my ($self) = @_;
    return {
        template => $self->template->to_jstmpl,
        %{ $self->next::method },
    };
}


1;
