package Judoon::Lookup::Role::WebFetch;

use LWP::UserAgent;
use MooX::Types::MooseLike::Base qw(Str InstanceOf);

use Moo::Role;

has agent_contact => (
    is      => 'lazy',
    isa     => Str,
    default => 'felliott@virginia.edu',
);


has agent => (
    is  => 'lazy',
    isa => InstanceOf['LWP::UserAgent'],
);
sub _build_agent {
    my ($self) = @_;

    my $agent = LWP::UserAgent->new(
        agent => "libwww-perl " . $self->agent_contact
    );
    push @{$agent->requests_redirectable}, 'POST';
    return $agent;
}



1;
__END__

=pod

=for stopwords redirectable

=encoding utf8

=head1 NAME

Judoon::Lookup::Role::WebFetch - Provides an LWP::UserAgent attribute

=head1 DESCRIPTION

This role provides a default L<LWP::UserAgent> attribute suitable for
fetching data from external web APIs.

=head1 ATTRIBUTES

=head2 agent_contact

The email address of the person administering the code.  Included in
the user-agent string so they can be contacted by the web API
providers if needed.  Defaults to Fitz's email address.

=head2 agent

An instance of L<LWP::UserAgent> with the L</agent_contact> added to
the user-agent and with redirectable POSTs enabled.

=head1 AUTHOR

Fitz ELLIOTT <felliott@fiskur.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by the Rector and Visitors of the
University of Virginia.

This is free software, licensed under:

 The Artistic License 2.0 (GPL Compatible)

=cut
