package t::Role::TmplFixtures;

=pod

=encoding utf-8

=head1 NAME

t::Role::TmplFixtures - provide standard Judoon::Tmpl fixtures

=head1 DESCRIPTION

Test files using L</Test::Roo> can consume this role to get sets of
standard data for passing to Judoon::Tmpl.

=cut

use Data::Section::Simple qw(get_data_section);
use Judoon::Tmpl;
use MooX::Types::MooseLike::Base qw(HashRef);

use Test::Roo::Role;

requires 'decode_json';

=head1 ATTRIBUTES / METHODS

=head2 tmpl_fixtures / _build_tmpl_fixtures

A for useful tmpl fixture sets.

=cut

has tmpl_fixtures => (
    is          => 'lazy',
    isa         => HashRef,
);
sub _build_tmpl_fixtures {
    my ($self) = @_;

    my %fixtures = map { $_ => {
        jstmpl  => get_data_section("${_}_jstmpl"),
        native  => get_data_section("${_}_native"),
        widgets => $self->decode_json( get_data_section("${_}_native") ),
    } } qw(basic_equiv invalid);

    for my $fixture (values %fixtures) {
        chomp $fixture->{jstmpl};
        chomp $fixture->{native};
    }

    return \%fixtures;
}

=head3 get_tmpl_fixture( $fixture_name )

Get the fixture called C<$fixture_name> or die screaming.

=head3 add_tmpl_fixture( $fixture_name, $type, $fixture )

Add a new fixture definition to the internal fixtures
dictionary. C<$type> must be one of C<jstmpl|native|widgets>.

=cut

sub get_tmpl_fixture {
    my ($self, $key) = @_;
    return $self->tmpl_fixtures->{$key} or die "No such tmpl fixture: $key";
}

sub add_tmpl_fixture {
    my ($self, $key, $type, $fixture) = @_;
    die "Bad type **$type** passed to add_tmpl_fixtures"
        unless ($type =~ m/^(?:jstmpl|native|widgets)$/);
    $self->fixtures->{$key}{$type} = $fixture;
}


1;


__DATA__
@@ basic_equiv_jstmpl
<strong><em>foo</em></strong><strong>{{bar}}</strong><br><em><a href="pre{{baz}}post">quux</a></em>
@@ basic_equiv_native
[
 {"type" : "text", "value" : "foo", "formatting" : ["italic", "bold"]},
 {"type" : "variable", "name" : "bar", "formatting" : ["bold"]},
 {"type" : "newline", "formatting" : []},
 {
   "type" : "link",
   "url"  : {
     "varstring_type"    : "variable",
     "type"              : "varstring",
     "accession"         : "",
     "text_segments"     : ["pre","post"],
     "variable_segments" : ["baz",""],
     "formatting"        : []
   },
   "label" : {
     "varstring_type"    : "static",
     "type"              : "varstring",
     "accession"         : "",
     "text_segments"     : ["quux"],
     "variable_segments" : [""],
     "formatting"        : []
   },
  "formatting" : ["italic"]
 }
]
@@ invalid_jstmpl
<a href="foo"><p>thing</p></a>
@@ invalid_native
[{"type" : "moo"}]
