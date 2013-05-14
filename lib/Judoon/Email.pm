package Judoon::Email;

=pod

=for stopwords

=encoding utf-8

=head1 NAME

Judoon::Email - Construct Judoon-related emails

=head1 SYNOPSIS

 use Judoon::Email;

 my $email = Judoon::Email->new_password_reset({
     reset_uri => 'http://example.com/reset?token=deadbeef
 });

=head1 DESCRIPTION

C<Judoon::Email> is an object that builds emails. It abstracts away
the common configuration elements.

=cut

use Moo;
use MooX::Types::MooseLike::Base qw(Str);

use Email::MIME::Kit;


=head1 ATTRIBUTES

=head2 kit_path

Path to the L<Email::MIME::Kit> kits. Required.

=cut

has kit_path => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);


=head1 METHODS

=head2 new_password_reset( \%args )

Builds and returns a new 'Reset your password' email.  L<args> must
have a C<reset_uri> key.

=cut

sub new_password_reset {
    my ($self, $vars) = @_;

    die q{Missing required 'reset_uri' field}
        unless ($vars->{reset_uri});
    my $kit = Email::MIME::Kit->new({
        source => $self->kit_path . '/password_reset.mkit',
    });
    return $kit->assemble($vars);
}


1;
__END__
