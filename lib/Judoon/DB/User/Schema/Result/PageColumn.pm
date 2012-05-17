use utf8;
package Judoon::DB::User::Schema::Result::PageColumn;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Judoon::DB::User::Schema::Result::PageColumn

=cut

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

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

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "page_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "title",
  { data_type => "text", is_nullable => 0 },
  "template",
  { data_type => "text", is_nullable => 0 },
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

Related object: L<Judoon::DB::User::Schema::Result::Page>

=cut

__PACKAGE__->belongs_to(
  "page",
  "Judoon::DB::User::Schema::Result::Page",
  { id => "page_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07017 @ 2012-02-28 16:31:02
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:aX9vDbJcTpDsvGsCsgYoCg

use Judoon::Tmpl::Translator;
has translator => (is => 'ro', isa => 'Judoon::Tmpl::Translator', lazy_build => 1);
sub _build_translator { return Judoon::Tmpl::Translator->new; }

sub template_to_jquery {
    my ($self) = @_;
    return $self->translator->translate(
        from => 'Native', to => 'JQueryTemplate', template => $self->template
    );
}

sub template_to_webwidgets {
    my ($self) = @_;
    return $self->translator->translate(
        from => 'Native', to => 'WebWidgets', template => $self->template
    );
}

sub template_to_objects {
    my ($self) = @_;
    return $self->translator->to_objects(
        from => 'Native', template => $self->template
    );
}

sub set_template {
    my ($self, @objects) = @_;
    $self->template($self->translator->from_objects(
        to => 'Native', objects => \@objects,
    ));
}

# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
