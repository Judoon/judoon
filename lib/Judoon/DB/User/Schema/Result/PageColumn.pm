use utf8;
package Judoon::DB::User::Schema::Result::PageColumn;

=pod

=encoding utf8

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


=head1 METHODS

=head2 B<C< translator / _build_translator >>

Attribute / accessor to hold the C<L<Judoon::Tmpl::Translator>>
utility object.

=cut

use Judoon::Tmpl::Translator;
has translator => (is => 'lazy',); # isa => 'Judoon::Tmpl::Translator',);
sub _build_translator { return Judoon::Tmpl::Translator->new; }


=head2 B<C< template_to_jquery >>

Translate the stored template into a JQuery template.

=cut

sub template_to_jquery {
    my ($self) = @_;
    return $self->translator->translate(
        from => 'Native', to => 'JQueryTemplate', template => $self->template
    );
}


=head2 B<C< template_to_objects >>

Translate the stored template into a list of C<L<Judoon::Tmpl::Node>>
objects.

=cut

sub template_to_objects {
    my ($self) = @_;
    return $self->translator->to_objects(
        from => 'Native', template => $self->template
    );
}


=head2 B<C< set_template >>

Given a list of C<L<Judoon::Tmpl::Node>>s, save them to the
L</template> field.

=cut

sub set_template {
    my ($self, @objects) = @_;
    $self->template($self->translator->from_objects(
        to => 'Native', objects => \@objects,
    ));
}


1;
