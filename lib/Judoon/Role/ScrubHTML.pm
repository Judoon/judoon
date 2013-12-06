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
