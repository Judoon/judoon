package Judoon::Schema::Result::Page;

=pod

=encoding utf8

=head1 NAME

Judoon::Schema::Result::Page

=cut

use Moo;
extends 'Judoon::Schema::Result';


use JSON qw(to_json from_json);
use Judoon::Error::InvalidTemplate;

# default options for serializing C<Page> objects as JSON.
# this gets passed to to_json().
my $json_opts = {utf8 => 1, pretty => 1,};


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
    id => {
        data_type         => "integer",
        is_auto_increment => 1,
        is_nullable       => 0,
    },
    dataset_id => {
        data_type      => "integer",
        is_foreign_key => 1,
        is_nullable    => 0,
    },
    title => {
        data_type   => "text",
        is_nullable => 0,
    },
    preamble => {
        data_type   => "text",
        is_nullable => 0,
    },
    postamble => {
        data_type   => "text",
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

=head2 dataset

Type: belongs_to

Related object: L<Judoon::Schema::Result::Dataset>

=cut

__PACKAGE__->belongs_to(
    dataset => "::Dataset",
    { id => "dataset_id" },
    { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 page_columns

Type: has_many

Related object: L<Judoon::Schema::Result::PageColumn>

=cut

__PACKAGE__->has_many(
    page_columns => "::PageColumn",
    { "foreign.page_id" => "self.id" },
    { cascade_copy => 0, cascade_delete => 1 },
);


=head1 EXTRA COMPONENTS

=head2 ::Role::Result::HasPermissions

Add C<permission> column / methods to C<Page>.

=head2 ::Role::Result::HasTimestamps

Add <created> and <modified> columns to C<Page>.

=cut

with qw(
    Judoon::Schema::Role::Result::HasPermissions
    Judoon::Schema::Role::Result::HasTimestamps
);
__PACKAGE__->register_permissions;
__PACKAGE__->register_timestamps;



=head1 METHODS

=head2 page_columns_ordered()

Get this C<Page>'s C<PageColumn>s in sorted order

=cut

sub page_columns_ordered {
    my ($self) = @_;
    return $self->page_columns_rs->search_rs({},{order_by => {-asc => 'sort'}});
}


=head2 nbr_columns()

Number of columns in this page.

=cut

sub nbr_columns {
    my ($self) = @_;
    return $self->page_columns_rs->count;
}


=head2 nbr_rows()

Number of rows in this page.

=cut

sub nbr_rows {
    my ($self) = @_;
    return $self->dataset->nbr_rows;
}


=head2 clone_from_existing( $page_obj )

Clone a new page using the structure of C<$page_obj>, another
C<Page> row object.

=cut

sub clone_from_existing {
    my ($self, $other_page) = @_;

    $self->result_source->schema->txn_do(
        sub {

            # copy their page to ours
            my %page_clone = $other_page->get_cloneable_columns();
            $self->set_columns( \%page_clone );
            $self->insert;

            # make sure their referenced dataset columns are also in our
            # dataset
            my @other_page_columns = $other_page->page_columns_ordered->all;
            $self->templates_match_dataset(@other_page_columns);

            # copy their columns to our page
            for my $pagecol (@other_page_columns) {
                my %column_clone = $pagecol->get_cloneable_columns();
                $self->create_related('page_columns', \%column_clone);
            }
        }
    );

    return $self;
}


=head2 templates_match_dataset( @page_columns )

Validate that the C<Tmpl::Node::Variable>s in the PageColumn template
are valid references to DatasetColumns in the parent Dataset.

=cut

sub templates_match_dataset {
    my ($self, @page_columns) = @_;

    if (not @page_columns) {
        @page_columns = $self->page_columns_ordered->all;
    }

    my %valid_ds_columns = map {$_->shortname => 1}
        $self->dataset->ds_columns_rs->all;
    my @bad_columns;
    for my $page_column (@page_columns) {
        my $template  = $page_column->template;
        my @variables = $template->get_variables();
        if (my @invalid = grep {not $valid_ds_columns{$_}} @variables) {
            push @bad_columns, {
                column   => $page_column,
                template => $template,
                invalid  => \@invalid,
            };
        }
    }

    if (@bad_columns) {
        Judoon::Error::InvalidTemplate->throw({
            message       => 'Some templates reference non-existing columns in the dataset',
            templates     => \@bad_columns,
            valid_columns => [keys %valid_ds_columns],
        });
    }
    return 1;
}


=head2 dump_to_user()

Return a json representation of the Page.  The PageColumn templates
are saved as data structures instead of json strings, to avoid
double-quoting.  This should make it easier for the user to edit the
page column templates.

=cut

sub dump_to_user {
    my ($self) = @_;

    my %page = $self->get_cloneable_columns();
    for my $page_column ($self->page_columns_ordered->all) {
        my %page_cols = $page_column->get_cloneable_columns();
        $page_cols{template} = $page_column->template->to_data;
        push @{ $page{page_columns} }, \%page_cols;
    }

    return to_json(\%page, $json_opts);
}


=head2 clone_from_dump( $page_json )

Clone a new page from a json dump of a previous page.

=cut

sub clone_from_dump {
    my ($self, $page_json) = @_;

    my $other_page = from_json($page_json, $json_opts);
    $self->result_source->schema->txn_do(
        sub {

            my $other_page_columns = delete $other_page->{page_columns};

            # copy their page to ours
            $self->set_columns( $other_page );
            $self->insert;

            # create new PageColumn objects, but don't insert them
            # yet.
            my @new_pagecols;
            for my $pagecol (@$other_page_columns) {
                my $template = delete $pagecol->{template};
                $pagecol->{template}
                    = Judoon::Tmpl->new_from_data($template)->to_native;
                push @new_pagecols, $self->new_related('page_columns', $pagecol);
            }

            # make sure their referenced dataset columns are also in
            # our dataset
            $self->templates_match_dataset(@new_pagecols);

            $_->insert for (@new_pagecols);
        }
    );

    return $self;
}


=head2 get_cloneable_columns()

Get the columns of this Page that are suitable for cloning,
i.e. everything but foreign keys.

=cut

sub get_cloneable_columns {
    my ($self) = @_;
    my %me = $self->get_columns;
    delete $me{id};
    delete $me{dataset_id};
    return %me;
}


1;
