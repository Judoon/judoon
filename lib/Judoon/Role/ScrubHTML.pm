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

use HTML::Scrubber;
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
    isa => InstanceOf['HTML::Scrubber'],
);
sub _build_html_block_scrubber {
    my ($self) = @_;
    my $scrubber = HTML::Scrubber->new;
    $scrubber->{_p}->closing_plaintext(1);
    $scrubber->rules(
        (map {$_ => 1} @inline_tags, @block_tags),
        p          => {style => 1,},
        span       => {style => 1,},
        a          => {href => 1, target => 1,},
        table      => {style => 1,},
        thead      => {style => 1,},
        tbody      => {style => 1,},
        tfoot      => {style => 1,},
        tr         => {style => 1,},
        th         => {style => 1, colspan => 1, rowspan => 1,},
        td         => {style => 1, colspan => 1, rowspan => 1,},
        (map {$_ => 0} @structure_tags, @head_tags, @invalid_tags,
         @obsolete_tags, @advanced_tags, @form_tags),
    );
    return $scrubber;
}


=head2 html_string_scrubber

This scrubber permits HTML that is appropriate for inline-level
elements.

=cut

has html_string_scrubber => (
    is  => 'lazy',
    isa => InstanceOf['HTML::Scrubber'],
);

sub _build_html_string_scrubber {
    my ($self) = @_;
    my $scrubber = HTML::Scrubber->new;
    $scrubber->{_p}->closing_plaintext(1);
    $scrubber->rules(
        (map {$_ => 1} @inline_tags),
        span   => {style => 1,},
        a      => {href => 1, target => 1,},
        (map {$_ => 0} @structure_tags, @head_tags, @invalid_tags,
         @obsolete_tags, @advanced_tags, @form_tags, @block_tags),

    );
    return $scrubber;
}



=head1 METHODS

=head2 scrub_html_block( $string )

Scrub untrusted HTML from C<$string>. Most regular block-level HTML
elements are permitted.

=cut

sub scrub_html_block {
    my ($self, $str) = @_;
    return defined($str) ? $self->html_block_scrubber->scrub($str) : q{};
}


=head2 scrub_html_string( $string )

Remove all block-level HTML elements from C<$string>.

=cut

sub scrub_html_string {
    my ($self, $str) = @_;
    return defined($str) ? $self->html_string_scrubber->scrub($str) : q{};
}



1;
__END__
