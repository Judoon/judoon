use utf8;
package Judoon::DB::User::Schema::Result::Page;

=pod

=encoding utf8

=head1 NAME

Judoon::DB::User::Schema::Result::Page

=cut

use Moo;
extends 'DBIx::Class::Core';

=head1 TABLE: C<pages>

=cut

__PACKAGE__->table("pages");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 dataset_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 title

  data_type: 'text'
  is_nullable: 0

=head2 preamble

  data_type: 'text'
  is_nullable: 0

=head2 postamble

  data_type: 'text'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "dataset_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "title",
  { data_type => "text", is_nullable => 0 },
  "preamble",
  { data_type => "text", is_nullable => 0 },
  "postamble",
  { data_type => "text", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 dataset

Type: belongs_to

Related object: L<Judoon::DB::User::Schema::Result::Dataset>

=cut

__PACKAGE__->belongs_to(
  "dataset",
  "Judoon::DB::User::Schema::Result::Dataset",
  { id => "dataset_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 page_columns

Type: has_many

Related object: L<Judoon::DB::User::Schema::Result::PageColumn>

=cut

__PACKAGE__->has_many(
  "page_columns",
  "Judoon::DB::User::Schema::Result::PageColumn",
  { "foreign.page_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 1 },
);


# add permission column / methods to Page
with qw(Judoon::DB::User::Schema::Role::Result::HasPermissions);
__PACKAGE__->register_permissions;


=head1 METHODS

=head2 B<C<page_columns_ordered>>

Get this Page's PageColumns in sorted order

=cut

sub page_columns_ordered {
    my ($self) = @_;
    return $self->page_columns_rs->search({},{order_by => {-asc => 'sort'}});
}


=head2 B<C<nbr_columns>>

Number of columns in this page.

=cut

sub nbr_columns {
    my ($self) = @_;
    my @columns = $self->page_columns;
    return scalar @columns;
}


=head2 B<C<nbr_rows>>

Number of rows in this page.

=cut

sub nbr_rows {
    my ($self) = @_;
    return $self->dataset->nbr_rows;
}


=head2 B<C<clone_from_existing>>

Clone a new page from an existing page

=cut

sub clone_from_existing {
    my ($self, $other_page) = @_;

    $self->result_source->schema->txn_do(
        sub {

            # this is not a problem
            my %page_clone = $other_page->get_columns;
            delete $page_clone{id};
            delete $page_clone{dataset_id};
            $self->set_columns( \%page_clone );
            $self->insert;

            # need to validate that their page_columns works with our dataset
            for my $pagecol ($other_page->page_columns_ordered->all) {
                # $self->validate()
                my %column_clone = $pagecol->get_columns;
                delete $column_clone{id};
                delete $column_clone{page_id};
                $self->create_related('page_columns', \%column_clone);
            }

        }
    );

    return $self;
}

1;
