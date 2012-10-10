use utf8;
package Judoon::DB::User::Schema::Result::PageColumn;

=head1 NAME

Judoon::DB::User::Schema::Result::PageColumn

=cut

use Moo;
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



=pod

=encoding utf8

=cut


use Judoon::Tmpl::Translator;
has translator => (is => 'lazy',); # isa => 'Judoon::Tmpl::Translator',);
sub _build_translator { return Judoon::Tmpl::Translator->new; }

sub template_to_jquery {
    my ($self) = @_;
    return $self->translator->translate(
        from => 'Native', to => 'JQueryTemplate', template => $self->template
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


1;
