package Judoon::Email;

=pod

=for stopwords

=encoding utf-8

=head1 NAME

Judoon::Email - Send judoon-related emails

=head1 SYNOPSIS

 use Judoon::Email;

 Judoon::Email->new->send_email(
   to => 'soandso@example.com',
   from_nick => 'webapp',
   subject => 'Heere yo go',
   content => $content_of_email,
 );

=head1 DESCRIPTION

C<Judoon::Email> is an object that sends email for us.

=cut

use Moo;
use MooX::Types::MooseLike::Base qw(Str);

use Email::MIME::Kit;


has kit_path => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);


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
