package t::Role::HtmlFixtures;

=pod

=encoding utf-8

=head1 NAME

t::Role::HtmlFixtures - provide standard HTML scrubbing fixtures

=head1 DESCRIPTION

Test files using L</Test::Roo> can consume this role to get sets of
standard data for testing HTML scrubbing ability

=cut

use Data::Section::Simple qw(get_data_section);
use List::Util qw();
use Types::Standard qw(HashRef);

use Test::Roo::Role;


my @fixture_types = qw(tainted scrubbed_string scrubbed_block);
my @fixture_sets  = qw(
    basic basic_entity simple_html scary_html simple_block
    encoded_scary long_block
);


=head1 ATTRIBUTES

=head2 html_fixtures / _build_html_fixtures

Useful fixture sets for testing HTML scrubbing.

=cut

has html_fixtures => (
    is  => 'lazy',
    isa => HashRef,
);
sub _build_html_fixtures {
    my ($self) = @_;

    my %fixtures;
    for my $set (@fixture_sets) {
        for my $type (@fixture_types) {
            $fixtures{$set}{$type} = get_data_section("${set}-${type}");
            die "Missing HTML fixture: ${set}-${type}"
                unless (defined $fixtures{$set}{$type});
            chomp $fixtures{$set}{$type};
        }
    }

    return \%fixtures;
}


=head1 METHODS

=head2 get_html_fixture( $fixture_name )

Get the fixture called C<$fixture_name> or die screaming.

=head2 add_html_fixture( $fixture_name, $type, $fixture )

Add a new fixture definition to the internal fixtures
dictionary. C<$type> must match one of the entries in
C<@fixture_types>.

=cut

sub get_html_fixture {
    my ($self, $key) = @_;
    return $self->html_fixtures->{$key} or die "No such html fixture: $key";
}

sub add_html_fixture {
    my ($self, $key, $type, $fixture) = @_;
    die "Bad type **$type** passed to add_html_fixtures()"
        unless (List::Util::first {$_ eq $type} @fixture_types);
    $self->html_fixtures->{$key}{$type} = $fixture;
}


1;


__DATA__
@@ basic-tainted
hey
@@ basic-scrubbed_string
hey
@@ basic-scrubbed_block
hey
@@ basic_entity-tainted
hey &amp; hi
@@ basic_entity-scrubbed_string
hey &amp; hi
@@ basic_entity-scrubbed_block
hey &amp; hi
@@ simple_html-tainted
<em>hey</em>
@@ simple_html-scrubbed_string
<em>hey</em>
@@ simple_html-scrubbed_block
<em>hey</em>
@@ scary_html-tainted
<script>hey</script>
@@ scary_html-scrubbed_string

@@ scary_html-scrubbed_block

@@ simple_block-tainted
<p>hey</p>
@@ simple_block-scrubbed_string
hey
@@ simple_block-scrubbed_block
<p>hey</p>
@@ encoded_scary-tainted
&lt;script&gt;hey&lt;/script&gt;
@@ encoded_scary-scrubbed_string
&lt;script&gt;hey&lt;/script&gt;
@@ encoded_scary-scrubbed_block
&lt;script&gt;hey&lt;/script&gt;
@@ long_block-tainted
<p><strong>Mogilner A</strong> , Edelstein-Keshet L. Regulation of actin dynamics in rapidly moving cells: a quantitative analysis. Biophys J. 2002;83(3):1237-58.</p>
@@ long_block-scrubbed_string
<strong>Mogilner A</strong> , Edelstein-Keshet L. Regulation of actin dynamics in rapidly moving cells: a quantitative analysis. Biophys J. 2002;83(3):1237-58.
@@ long_block-scrubbed_block
<p><strong>Mogilner A</strong> , Edelstein-Keshet L. Regulation of actin dynamics in rapidly moving cells: a quantitative analysis. Biophys J. 2002;83(3):1237-58.</p>
@@ placeholder-tainted
@@ placeholder-scrubbed_string
@@ placeholder-scrubbed_block
@@ placeholder-tainted
@@ placeholder-scrubbed_string
@@ placeholder-scrubbed_block
@@ placeholder-tainted
@@ placeholder-scrubbed_string
@@ placeholder-scrubbed_block
@@ placeholder-tainted
@@ placeholder-scrubbed_string
@@ placeholder-scrubbed_block
@@ placeholder-tainted
@@ placeholder-scrubbed_string
@@ placeholder-scrubbed_block
