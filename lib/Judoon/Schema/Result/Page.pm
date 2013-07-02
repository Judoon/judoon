package Judoon::Schema::Result::Page;

=pod

=encoding utf8

=head1 NAME

Judoon::Schema::Result::Page

=cut

use Judoon::Schema::Candy;
use Moo;
with 'Judoon::Role::JsonEncoder';


use Judoon::Error::Devel::Foreign;
use Judoon::Error::Template;
use Template;


table 'pages';

primary_column id => {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
};
column dataset_id => {
    data_type      => "integer",
    is_foreign_key => 1,
    is_nullable    => 0,
};
column title => {
    data_type       => "text",
    is_nullable     => 0,
    is_serializable => 1,
};
column preamble => {
    data_type       => "text",
    is_nullable     => 0,
    is_serializable => 1,
};
column postamble => {
    data_type       => "text",
    is_nullable     => 0,
    is_serializable => 1,
};


belongs_to dataset => "::Dataset",
    { id => "dataset_id" },
    { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" };

has_many page_columns => "::PageColumn",
    { "foreign.page_id" => "self.id" },
    { cascade_copy => 0, cascade_delete => 1 };


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
        Judoon::Error::Template->throw({
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

    $self->_json_encoder->pretty(1);
    return $self->encode_json(\%page);
}


=head2 clone_from_dump( $page_json )

Clone a new page from a json dump of a previous page.

=cut

sub clone_from_dump {
    my ($self, $page_json) = @_;

    my $other_page = $self->decode_json($page_json);
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


=head2 headers

Get an arrayref of page headers

=cut

sub headers {
    my ($self) = @_;
    return [map {$_->title} $self->page_columns_ordered->all];
}


=head2 data_table

Get an arrayref of arrayrefs of the page data

=cut

sub data_table {
    my ($self) = @_;

    my @col_templates = map {$_->template->to_jstmpl}
        $self->page_columns_ordered->all;

    my $data = $self->dataset->data_table({shortname => 1});
    my $data_labels = shift @$data; # get rid of headers


    my $tt = Template->new({
        START_TAG => quotemeta('{{'),
        END_TAG   => quotemeta('}}'),
    }) or Judoon::Error::Devel::Foreign->throw({
        message         => "Can't build a Template object w/ handlebars syntax",
        module          => 'Template',
        foreign_message => Template->error,
    });

    my @page_data;
    for my $data_row (@$data) {
        my %vars;
        @vars{@$data_labels} = @$data_row;

        my @page_row;
        for my $col_tmpl (@col_templates) {
            my $cell;
            $tt->process(\$col_tmpl, \%vars, \$cell)
                or Judoon::Error::Devel::Foreign->throw({
                    message         => "Can't fill template",
                    module          => 'Template',
                    foreign_message => $tt->error,
                });
            push @page_row, $cell;
        }
        push @page_data, \@page_row;
    }

    return \@page_data;
}


sub TO_JSON {
    my ($self) = @_;
    return {
        nbr_rows    => 0+$self->nbr_rows,
        nbr_columns => 0+$self->nbr_columns,
        %{ $self->next::method },
    };
}

1;
