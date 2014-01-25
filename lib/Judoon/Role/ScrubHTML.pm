package Judoon::Role::ScrubHTML;

=pod

=encoding utf8

=head1 NAME

Judoon::Role::ScrubHTML - Scrub HTML from untrusted input

=head1 SYNOPSIS

 package My::API;

 use Moo;
 with 'Judoon::Role::ScrubHTML';

 sub update {
   my ($self, $input);
   $input->{content} = $self->scrub_html_block($input->{content});
   $self->_insert_data($input);
 }

 l;

=head1 DESCRIPTION

This role provides a number of pre-defined scrubbers for removing
invalid HTML from user input.  This is for user input where some
subset of HTML is allowed, but not everything.

=cut

use HTML::Restrict;
use Types::Standard qw(InstanceOf);


use Moo::Role;


=head1 ATTRIBUTES

=head2 html_block_scrubber

This scrubber permits HTML that is appropriate for block-level
elements.

=cut


# see cmc-notes.org: Valid / Invalid HTML Tags
# valid
my @inline_tags = qw(
    a abbr b bdi bdo cite code del dfn em i ins kbd mark meter q s
    samp small span strong sub sup time u var wbr
);
my @block_tags = qw(
    address article aside blockquote br caption col colgroup dd details
    div dl dt figcaption figure footer h1 h2 h3 h4 h5 h6 header hr img li
    nav ol p pre section summary table tbody td tfoot th thead tr ul
);

# maybe valid one day
my @advanced_tags = qw(
    area audio canvas content data decorator element embed
    keygen main map menu menuitem object param progress
    rp rt ruby shadow source template track video
);
my @form_tags = qw(
    button datalist fieldset form input label legend
    optgroup option output select textarea
);

#invalid
my @structure_tags = qw(body head html);
my @head_tags      = qw(base link meta title);
my @invalid_tags   = qw(iframe noscript script style);
my @obsolete_tags  = qw(
    acronym applet basefont bgsound big blink center dir
    font frame frameset hgroup isindex listing marquee
    nobr noframes plaintext spacer strike tt xmp
);


has html_block_scrubber => (
    is  => 'lazy',
    isa => InstanceOf['HTML::Restrict'],
);
sub _build_html_block_scrubber {
    my ($self) = @_;
    my $scrubber = HTML::Restrict->new({
        rules => {
            (map {$_ => []} @inline_tags, @block_tags),
            a          => [qw(href target          )],
            p          => [qw(style                )],
            span       => [qw(style                )],
            table      => [qw(style                )],
            thead      => [qw(style                )],
            tbody      => [qw(style                )],
            tfoot      => [qw(style                )],
            tr         => [qw(style                )],
            th         => [qw(style colspan rowspan)],
            td         => [qw(style colspan rowspan)],
            # (map {$_ => 0} @structure_tags, @head_tags, @invalid_tags,
            #  @obsolete_tags, @advanced_tags, @form_tags),
        },
    });
    $scrubber->parser->closing_plaintext(1);
    return $scrubber;
}


=head2 html_string_scrubber

This scrubber permits HTML that is appropriate for inline-level
elements.

=cut

has html_string_scrubber => (
    is  => 'lazy',
    isa => InstanceOf['HTML::Restrict'],
);

sub _build_html_string_scrubber {
    my ($self) = @_;
    my $scrubber = HTML::Restrict->new({
        rules => {
            (map {$_ => []} @inline_tags),
            span   => [qw(style      )],
            a      => [qw(href target)],
            # (map {$_ => 0} @structure_tags, @head_tags, @invalid_tags,
            #  @obsolete_tags, @advanced_tags, @form_tags, @block_tags),
        },
    });
    $scrubber->parser->closing_plaintext(1);
    return $scrubber;
}



=head1 METHODS

=head2 scrub_html_block( $string )

Scrub untrusted HTML from C<$string>. Most regular block-level HTML
elements are permitted.

=cut

sub scrub_html_block {
    my ($self, $str) = @_;
    return $self->html_block_scrubber->process($str) // q{};
}


=head2 scrub_html_string( $string )

Remove all block-level HTML elements from C<$string>.

=cut

sub scrub_html_string {
    my ($self, $str) = @_;
    return $self->html_string_scrubber->process($str) // q{};
}



1;
__END__

=head1 AUTHOR

Fitz ELLIOTT <felliott@fiskur.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by the Rector and Visitors of the
University of Virginia.

This is free software, licensed under:

 The Artistic License 2.0 (GPL Compatible)

=cut
