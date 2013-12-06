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

use Encode::ZapCP1252 ();
use HTML::Entities ();
use HTML::Scrubber;
use HTML::TreeBuilder;
use Types::Standard qw(InstanceOf);


use Moo::Role;


=head1 ATTRIBUTES

=head2 html_block_scrubber

This scrubber permits HTML that is appropriate for block-level
elements.

=cut

has html_block_scrubber => (
    is  => 'lazy',
    isa => InstanceOf['HTML::Scrubber'],
);
sub _build_html_block_scrubber {
    my ($self) = @_;
    my $scrubber = HTML::Scrubber->new;
    $scrubber->rules(
        strong     => 1,
        em         => 1,
        p          => {style => 1,},
        sub        => 1,
        sup        => 1,
        span       => {style => 1,},
        a          => {href => 1, target => 1,},
        blockquote => 1,
        table      => {style => 1,},
        thead      => {style => 1,},
        tbody      => {style => 1,},
        tfoot      => {style => 1,},
        tr         => {style => 1,},
        th         => {style => 1, colspan => 1, rowspan => 1,},
        td         => {style => 1, colspan => 1, rowspan => 1,},
        ol         => 1,
        ul         => 1,
        li         => 1,
        hr         => 1,
        h1         => 1,
        h2         => 1,
        h3         => 1,
        h4         => 1,
        h5         => 1,
        h6         => 1,
        pre        => 1,
        address    => 1,
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
    $scrubber->rules(
        strong => 1,
        em     => 1,
        p      => 0,
        sub    => 1,
        sup    => 1,
        span   => {style => 1,},
        a      => {href => 1, target => 1,},
    );
    return $scrubber;
}


=head2 plain_scrubber

This scrubber removes all HTML from the input.

=cut

has plain_scrubber => (
    is  => 'lazy',
    isa => InstanceOf['HTML::Scrubber'],
);

sub _build_plain_scrubber {
    my ($self) = @_;
    return HTML::Scrubber->new(allow => []);
}


=head1 METHODS

=head2 scrub_html_block( $string )

Scrub untrusted HTML from C<$string>. Most regular block-level HTML
elements are permitted.

=head2 clean_html_block( $string )

Filter, scrub, and trim untrusted HTML in C<$string>.

=cut

sub scrub_html_block {
    my ($self, $str) = @_;
    return defined($str) ? $self->html_block_scrubber->scrub($str) : q{};
}

sub clean_html_block {
    my ($self, $str) = @_;
    return $self->_trim(
        $self->scrub_html_block(
            $self->_fix_misc_html($str)
        )
    );
}


=head2 scrub_html_string( $string )

Remove all block-level HTML elements from C<$string>.

=head2 clean_html_string( $string )

Filter, scrub, and trim block-level HTML elements in C<$string>.

=cut

sub scrub_html_string {
    my ($self, $str) = @_;
    return defined($str) ? $self->html_string_scrubber->scrub($str) : q{};
}

sub clean_html_string {
    my ($self, $str) = @_;
    return $self->_trim(
        $self->scrub_html_string(
            $self->_fix_misc_html($str)
        )
    );
}


=head2 scrub_plain_text( $string )

Remove all HTML from C<$string>.

=head2 clean_plain_text( $string )

Scrub all HTML, then filter and trim C<$string>.

=cut

sub scrub_plain_text {
    my ($self, $str) = @_;
    return defined($str) ? $self->plain_scrubber->scrub($str) : q{};
}

sub clean_plain_text {
    my ($self, $str) = @_;
    return $self->_trim(
        $self->scrub_plain_text(
            $self->_decode_to_plain_text($str)
        )
    );
}



=head2 Private Methods

=head3 _trim( $string )

Remove whitespace from beginning and end of C<$string>.

=cut

sub _trim {
    my ($self, $str) = @_;
    return q{} unless (defined $str);
    $str =~ s/^\s*//s;
    $str =~ s/\s*$//s;
    return $str;
}


=head3 _decode_to_plain_text( $string )

This function turns a possibly HTML string into plain text.  It uses
L<HTML::Entities> to decode HTML-escaped strings into plain text
characters.  It also replaces C<cp1252> (a Microsoft Word encoding)
characters into their standard utf-8 counterparts.

=cut

sub _decode_to_plain_text {
    my ($self, $str) = @_;
    return q{} unless (defined $str);

    HTML::Entities::decode_entities($str);
    Encode::ZapCP1252::zap_cp1252($str);

    return $str;
}


=head3 _fix_misc_html( $string )

Fix common problems with HTML. Currently includes:

 1.) fixes for bogus Microsoft greek character encodings
 2.) removing \r characters from input

=cut

sub _fix_misc_html {
    my ($self, $str) = @_;
    return q{} unless ($str);

    # handle bogus Microsoft greek character encoding
    $str =~ s/\x{f061}/\N{U+03B1}/g;
    $str =~ s/\x{f062}/\N{U+03B2}/g;

    # fix common errors:
    $str =~ s/\r//g;

    return $str;
}


=head3 _clean_msword_html( $string )

Microsoft Word produces some really weird HTML when a document's
contents are copied and pasted into a web browser.  This code removes
superfluous span and p tags.

=cut

sub _clean_msword_html {
    my ($self, $str) = @_;

    return q{} unless (defined $str);


    my $root = HTML::TreeBuilder->new;
    $root->implicit_tags(0);
    $root->parse($str);
    $root->eof;

    # MS Office adds lots of empty span tags
    my @spans = $root->find_by_tag_name('span');
    for my $span (@spans) {
        if (not $span->all_external_attr) {
            $span->replace_with_content->delete;
        }
    }

    # MS Office add lots of empty <p>s
    my @ps = $root->find_by_tag_name('p');
    for my $p (@ps) {
        my @content = $p->content_list;
        if ($p->is_empty ||
                (@content == 1 && !ref($content[0])
                     && $content[0] =~ m/^(?:\s*(?:&nbsp;\s*)?)$/) ) {
            $p->delete;
        }
    }

    # HTML::TreeBuilder adds <html>
    $str = $root->as_XML;
    $str =~ s{^<html>}{};
    $str =~ s{</html>$}{}s;
    $root->delete;

    return $str;
}


1;
__END__
