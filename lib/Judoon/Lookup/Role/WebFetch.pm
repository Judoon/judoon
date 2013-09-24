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
